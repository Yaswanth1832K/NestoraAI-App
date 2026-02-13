const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

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
