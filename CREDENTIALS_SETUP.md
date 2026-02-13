# 🗝️ Nestora-AI: Master Setup Guide

This guide provides a comprehensive, step-by-step walkthrough to set up the Nestora-AI environment from scratch. All sensitive keys and configuration files have been excluded from this repository for security.

---

## 1. Firebase Project Setup
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Click **Add project** and name it `house-rental-ai` (or your preferred name).
3.  **Authentication**:
    *   Navigate to **Build > Authentication**.
    *   Click **Get Started**.
    *   Enable **Email/Password** as a sign-in provider.
4.  **Firestore Database**:
    *   Navigate to **Build > Firestore Database**.
    *   Click **Create database**.
    *   Choose **Production mode** and a location close to you.
    *   **Rules**: Copy and paste the content of [firestore.rules](file:///c:/Users/yaswa/Desktop/Flutter/house_rental/firestore.rules) into the Rules tab.
5.  **Analytics & Messaging**:
    *   Enable Firebase Cloud Messaging (FCM) in Project Settings > Cloud Messaging.

---

## 2. Google Cloud & AI APIs
Nestora uses advanced AI and Maps features. You must enable these in the [Google Cloud Console](https://console.cloud.google.com/).

### 📍 Google Maps SDK for Android
1.  Go to **APIs & Services > Library**.
2.  Search for and enable **Maps SDK for Android**.
3.  Go to **Credentials > Create Credentials > API Key**.
4.  **Important**: Open [AndroidManifest.xml](file:///c:/Users/yaswa/Desktop/Flutter/house_rental/android/app/src/main/AndroidManifest.xml) and replace `"Enter your API Key here"` with your actual key.

### 🤖 Gemini AI (Google AI Studio)
1.  Go to [Google AI Studio](https://aistudio.google.com/).
2.  Click **Get API key**.
3.  **How to add**:
    *   **Option A**: Set an environment variable named `GEMINI_API_KEY`.
    *   **Option B**: Manually set it in [ai_service/main.py](file:///c:/Users/yaswa/Desktop/Flutter/house_rental/ai_service/main.py).

---

## 3. Firestore Schema & Indexes
While Firestore creates most indexes automatically, you must manually create the following **Composite Indexes** for complex features:

### 📑 Collections
The app will automatically create these documents, but you can pre-create them for safety:
-   `users`: Stores profile data and roles (`renter` or `owner`).
-   `listings`: Stores property details and `availableDates`.
-   `favorites`: Stores user specific saved properties.
-   `chats`: Stores conversation rooms and participants.
-   `bookings`: Stores visit requests and `visitDate`.

### ⚡ Manual Indexes (Required)
Go to **Firestore > Indexes > Composite** and click **Create Index**:

1.  **Favorites List**:
    *   Collection: `favorites`
    *   Fields: `userId` (Ascending) + `createdAt` (Descending)
2.  **Booking Search**:
    *   Collection: `bookings`
    *   Fields: `listingId` (Ascending) + `status` (Ascending) + `visitDate` (Ascending)

---

## 4. Python Backend Configuration (`ai_service`)
The Python server handles real-time notifications and AI chat.

1.  **Service Account Key**:
    *   Go to **Firebase Console > Project Settings > Service accounts**.
    *   Click **Generate new private key**.
    *   Download the JSON file, rename it to `serviceAccountKey.json`, and place it in the `ai_service/` directory.
2.  **Install Dependencies**:
    ```bash
    cd ai_service
    pip install -r requirements.txt
    ```
3.  **Run Server**:
    ```bash
    uvicorn main:app --reload
    ```

---

## 5. Flutter Frontend Configuration
1.  **Firebase Options**:
    *   Install the `flutterfire` CLI: `dart pub global activate flutterfire_cli`.
    *   Run `flutterfire configure` in the project root. This will generate `lib/firebase_options.dart`.
2.  **Build**:
    ```bash
    flutter pub get
    flutter run
    ```

---
**Security Reminder**: Never commit your `serviceAccountKey.json`, `firebase_options.dart`, or actual API keys to GitHub!
