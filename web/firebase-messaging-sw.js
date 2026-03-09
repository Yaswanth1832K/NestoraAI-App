importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker
const firebaseConfig = {
    apiKey: "AIzaSyCzWqmVkAd_BTlEhQRZypVulcCtMr5uaog",
    authDomain: "nestora-demo.firebaseapp.com",
    projectId: "nestora-demo",
    storageBucket: "nestora-demo.appspot.com",
    messagingSenderId: "1234567890",
    appId: "1:1234567890:web:1234567890" // Placeholder
};

try {
    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
        console.log("[firebase-messaging-sw.js] Received background message ", payload);
        const notificationTitle = payload.notification.title;
        const notificationOptions = {
            body: payload.notification.body,
            icon: '/icons/Icon-192.png'
        };
        self.registration.showNotification(notificationTitle, notificationOptions);
    });
} catch (e) {
    console.log("Firebase not initialized in worker");
}
