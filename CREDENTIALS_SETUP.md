# 🗝️ Nestora-AI: Credentials Setup Guide

To keeping this repository secure, sensitive API keys and service account files have been excluded from version control. Follow these steps to set up your local environment.

## 1. Firebase Service Account Key
The Python notification service requires a Google Cloud service account key to interact with Firestore and FCM.

- **File Path**: `ai_service/serviceAccountKey.json`
- **How to Get It**:
  1. Go to your [Firebase Console](https://console.firebase.google.com/).
  2. Project Settings > Service accounts.
  3. Click **Generate new private key**.
  4. Download the JSON file, rename it to `serviceAccountKey.json`, and place it inside the `ai_service/` directory.

## 2. Gemini AI API Key
The AI property assistant and search require a Google Gemini API key.

- **Option A (Environment Variable)**:
  Set an environment variable named `GEMINI_API_KEY` on your system or in your terminal:
  ```bash
  export GEMINI_API_KEY="your_actual_key_here"
  ```
- **Option B (Direct Edit)**:
  You can also manually re-add it to `ai_service/main.py`:
  ```python
  GEMINI_API_KEY = "your_actual_key_here"
  ```

## 3. Flutter Firebase Configuration
The Flutter app uses `lib/firebase_options.dart`. If this file is missing or you want to use a different Firebase project:
1. Install the Flutterfire CLI.
2. Run `flutterfire configure` in the root directory.

## 4. Google Maps API Key
The Flutter app uses Google Maps for property location visualization.

- **File Path**: `android/app/src/main/AndroidManifest.xml`
- **How to Set It**:
  1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
  2. Create a project and enable the **Maps SDK for Android**.
  3. Generate an API Key in **APIs & Services > Credentials**.
  4. Open `android/app/src/main/AndroidManifest.xml` and replace `"Enter your API Key here"` with your actual key:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_ACTUAL_API_KEY" />
     ```

---
**Security Note**: Never commit your `serviceAccountKey.json` or actual API keys to GitHub!
