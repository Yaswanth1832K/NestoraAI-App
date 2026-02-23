const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const LISTINGS_COLLECTION = "listings";

// Scam/safety pattern detection (no LLM). Flags phone numbers and advance-payment language.
function detectSafetySignals(description) {
  if (!description || typeof description !== "string") return { safety: "safe", signals: [] };
  const text = description.toLowerCase();
  const signals = [];
  // Indian phone: 10 digits, optional +91, spaces/dashes
  if (/\b(?:\+91[\s-]?)?[6-9]\d{9}\b/.test(description)) signals.push("Phone number in description");
  if (/\b\d{10,}\b/.test(description)) signals.push("Long number sequence");
  if (/advance\s+payment|pay\s+(?:first|before)|transfer\s+(?:first|before)|pay\s+in\s+advance/i.test(text)) signals.push("Advance payment language");
  if (/whatsapp|contact\s+me\s+at|call\s+me\s+on/i.test(text)) signals.push("Direct contact request");
  const safety = signals.length > 0 ? "suspicious" : "safe";
  return { safety, signals };
}

// Call Gemini to generate 3 bullet highlights from description (low-quota safe: one request).
async function generateSummaryBullets(description, apiKey) {
  if (!apiKey || !description) return null;
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`;
  const prompt = `From this property description, list exactly 3 short bullet-point highlights (one line each, no numbering). Description: ${description.slice(0, 1500)}`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 256, temperature: 0.3 },
      }),
    });
    const data = await res.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return null;
    const lines = text.split("\n").map((s) => s.replace(/^[\s\-*•]+/, "").trim()).filter(Boolean);
    return lines.slice(0, 3);
  } catch (e) {
    functions.logger.warn("Gemini summary error", e);
    return null;
  }
}

exports.onNewMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {

    const message = snap.data();
    const chatId = context.params.chatId;

    const chatDoc = await admin.firestore()
      .collection("chats")
      .doc(chatId)
      .get();

    const chatData = chatDoc.data();

    // Determine receiver
    const receiverId =
      message.senderId === chatData.ownerId
        ? chatData.renterId
        : chatData.ownerId;

    // Get receiver token
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(receiverId)
      .get();

    const token = userDoc.data().fcmToken;
    if (!token) return null;

    // Send notification
    await admin.messaging().send({
      token: token,
      notification: {
        title: "New Message",
        body: message.text,
      },
      data: {
        chatId: chatId,
      },
    });

    return null;
  });

exports.onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {

    const booking = snap.data();

    const ownerDoc = await admin.firestore()
      .collection("users")
      .doc(booking.ownerId)
      .get();

    const token = ownerDoc.data().fcmToken;
    if (!token) return null;

    await admin.messaging().send({
      token: token,
      notification: {
        title: "New Visit Request",
        body: "A renter requested to visit your property",
      },
      data: {
        chatId: booking.chatId,
      },
    });

    return null;
  });

exports.onBookingUpdated = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {

    const after = change.after.data();

    if (after.status !== "approved" && after.status !== "rejected")
      return null;

    const renterDoc = await admin.firestore()
      .collection("users")
      .doc(after.renterId)
      .get();

    const token = renterDoc.data().fcmToken;
    if (!token) return null;

    await admin.messaging().send({
      token: token,
      notification: {
        title: "Booking Update",
        body: `Your request was ${after.status}`,
      },
      data: {
        chatId: after.chatId,
      },
    });

    return null;
  });

// AI Listing Summary + Safety: on listing create/update, generate 3 bullets and set safety.
exports.onListingWritten = functions.firestore
  .document(`${LISTINGS_COLLECTION}/{listingId}`)
  .onWrite(async (change, context) => {
    const after = change.after.data();
    if (!after) return null;
    const listingId = context.params.listingId;
    const description = after.description || "";

    // Skip if already processed (avoid re-running on our own update)
    const existingBullets = after.aiSummaryBullets;
    const existingSafety = after.safety;
    if (existingBullets && existingBullets.length >= 3 && existingSafety) return null;

    const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key;
    const updates = {};

    // 1) Safety detection (no LLM)
    const { safety, signals } = detectSafetySignals(description);
    updates.safety = safety;
    if (signals.length > 0) {
      updates.fraudSignals = signals;
      updates.fraudRiskScore = Math.min(0.3 + signals.length * 0.2, 1);
    } else {
      updates.fraudSignals = admin.firestore.FieldValue.delete();
      updates.fraudRiskScore = admin.firestore.FieldValue.delete();
    }

    // 2) AI summary (Gemini) – only if missing
    if (!existingBullets || existingBullets.length < 3) {
      const bullets = await generateSummaryBullets(description, apiKey);
      if (bullets && bullets.length > 0) {
        updates.aiSummaryBullets = bullets.slice(0, 3);
      }
    }

    if (Object.keys(updates).length > 0) {
      await admin.firestore().collection(LISTINGS_COLLECTION).doc(listingId).update(updates);
    }
    return null;
  });
