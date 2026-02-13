# 🏠 Nestora AI: The Future of Smart Rentals

Nestora AI is a production-grade, two-sided rental marketplace that bridges the gap between property owners and renters using state-of-the-art AI. Built with **Flutter** and powered by a **Python FastAPI** AI microservice, Nestora simplifies the search, booking, and management of rental properties.

---

## 🌟 Core Features

### 🤖 Intelligent AI Assistance
- **AI Property Assistant**: Renters can chat directly with an AI context-aware assistant for any property to ask about amenities, rules, or local area details.
- **Natural Language Search**: Find homes using human language like *"Modern 2BHK near tech parks under 30k"*.
- **Smart Price Prediction**: Institutional-level analysis to determine if a listing is a "Great Deal" or "Overpriced" based on historical neighborhood data.

### 🛡️ Professional Management
- **Role-Based Access Control (RBAC)**: Distinct, secure experiences for Renters and Owners with backend-enforced permissions via Firestore rules.
- **Availability & Double-Booking Shield**: Owners can set specific visit dates, and our intelligent scheduling engine prevents multiple approved bookings for the same slot.
- **Real-Time visit Status**: Track the entire lifecycle of a visit request (Pending → Approved/Rejected) directly within the integrated chat interface.

### ⚡ Seamless Communication
- **Real-Time Chat**: Lightning-fast messaging between parties with instant Firestore streaming.
- **Free-Tier Push Notifications**: A custom Python-based notification engine that delivers real-time alerts to mobile devices without requiring a paid Firebase Blaze plan.
- **Deep Linking**: Tapping a notification takes you directly to the relevant conversation.

### 📍 Visual Discovery
- **Interactive Map Engine**: Discover properties using a high-performance map with dynamic markers and instant property previews.
- **Favorites System**: Save and track your dream homes with real-time sync across devices.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter, Riverpod (State Management), GoRouter (Reactive Routing).
- **Backend (Serverless)**: Firebase Auth, Cloud Firestore, Firebase Storage.
- **AI Microservice**: Python FastAPI, Google Gemini 2.5 Flash, Firebase Admin SDK.
- **Infrastructure**: Custom FCM Watcher for free-tier notifications.

---

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK (Latest Stable)
- Python 3.10+
- Firebase Project (Spark Plan)

### 2. Configuration
To keep this project secure, all sensitive credentials have been excluded. **You must follow the setup guide to run the project locally.**

📖 **[Master Credentials Setup Guide](CREDENTIALS_SETUP.md)**

### 3. Running the App
```bash
# 1. Start the AI Microservice
cd ai_service
pip install -r requirements.txt
uvicorn main:app --reload

# 2. Start the Flutter App
flutter pub get
flutter run
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
**Built for the future of real estate.** 🏠🚀✨
