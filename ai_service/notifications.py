import firebase_admin
from firebase_admin import credentials, messaging, firestore
import threading
import os
import time

class NotificationWatcher:
    def __init__(self, service_account_path="serviceAccountKey.json"):
        self.db = None
        self.initialized = False
        self.service_account_path = service_account_path
        
        # Try to initialize
        self.try_initialize()

    def try_initialize(self):
        try:
            if os.path.exists(self.service_account_path):
                print(f"📦 Initializing Firebase Admin from {self.service_account_path}...")
                cred = credentials.Certificate(self.service_account_path)
                firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                self.initialized = True
                print("✅ Firebase Admin initialized successfully.")
            else:
                print(f"⚠️ Warning: {self.service_account_path} not found. Notifications will be disabled until the file is provided.")
        except Exception as e:
            print(f"❌ Error initializing Firebase Admin: {str(e)}")

    def start_watching(self):
        if not self.initialized:
            # Check again in case the user added the file after startup
            self.try_initialize()
            if not self.initialized:
                return

        print("👂 Starting Firestore listeners for real-time notifications...")
        
        # 1. Listen for new messages (Collection Group)
        # Note: messaging on collection groups requires a specific index usually, 
        # but let's try root chats listening first for simplicity
        self.db.collection('chats').on_snapshot(self.on_chat_snapshot)
        
        # 2. Listen for new bookings
        self.db.collection('bookings').on_snapshot(self.on_booking_snapshot)

    def send_push_notification(self, token, title, body, data=None):
        if not token:
            return
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                token=token,
            )
            response = messaging.send(message)
            print(f"🚀 Successfully sent notification: {response}")
        except Exception as e:
            print(f"❌ Error sending notification: {str(e)}")

    def on_chat_snapshot(self, col_snapshot, changes, read_time):
        for change in changes:
            if change.type.name == 'ADDED':
                # This catches new chat rooms, but we want new messages.
                # A more robust way is to listen to a 'messages' collection group,
                # but let's implement subcollection listening if possible.
                chat_id = change.document.id
                # Add a listener for this specific chat's messages
                self.db.collection('chats').document(chat_id).collection('messages').on_snapshot(
                    lambda s, c, r, cid=chat_id: self.on_message_snapshot(cid, s, c, r)
                )

    def on_message_snapshot(self, chat_id, snapshots, changes, read_time):
        for change in changes:
            if change.type.name == 'ADDED':
                msg_data = change.document.to_dict()
                
                # Prevent echoing the notification logic for old messages
                # We only want messages created in the last 1 minute
                timestamp = msg_data.get('timestamp')
                if timestamp and (time.time() - timestamp.timestamp() > 60):
                    continue

                print(f"📩 New message in chat {chat_id}: {msg_data.get('text')}")
                self.process_new_message(chat_id, msg_data)

    def process_new_message(self, chat_id, message):
        try:
            chat_doc = self.db.collection('chats').document(chat_id).get()
            chat_data = chat_doc.to_dict()
            if not chat_data:
                print(f"⚠️ Warning: Chat {chat_id} not found.")
                return
            
            # Identify receiver
            sender_id = message.get('senderId')
            owner_id = chat_data.get('ownerId')
            renter_id = chat_data.get('renterId')
            
            receiver_id = renter_id if sender_id == owner_id else owner_id
            
            if not receiver_id:
                print(f"⚠️ Warning: Could not determine receiver for chat {chat_id}. (Owner: {owner_id}, Renter: {renter_id})")
                return

            # Get receiver's FCM token
            user_doc = self.db.collection('users').document(receiver_id).get()
            if user_doc.exists:
                token = user_doc.to_dict().get('fcmToken')
                if token:
                    self.send_push_notification(
                        token=token,
                        title="New Message",
                        body=message.get('text', 'You have a new message'),
                        data={"chatId": chat_id}
                    )
        except Exception as e:
            print(f"❌ Error processing message notification in chat {chat_id}: {str(e)}")

    def on_booking_snapshot(self, snapshots, changes, read_time):
        for change in changes:
            booking_data = change.document.to_dict()
            if change.type.name == 'ADDED':
                # New booking request
                print(f"📅 New booking request: {change.document.id}")
                self.process_booking_created(booking_data)
            elif change.type.name == 'MODIFIED':
                # Booking status update
                print(f"🔄 Booking updated: {change.document.id}")
                self.process_booking_updated(booking_data)

    def process_booking_created(self, booking):
        try:
            owner_id = booking.get('ownerId')
            if not owner_id or owner_id.strip() == "":
                print(f"⚠️ Warning: Booking missing valid ownerId. Data: {booking}")
                return

            user_doc = self.db.collection('users').document(owner_id).get()
            if user_doc.exists:
                token = user_doc.to_dict().get('fcmToken')
                if token:
                    self.send_push_notification(
                        token=token,
                        title="New Visit Request",
                        body="A renter requested to visit your property",
                        data={"chatId": booking.get('chatId', '')}
                    )
        except Exception as e:
            print(f"❌ Error processing booking creation: {str(e)}")

    def process_booking_updated(self, booking):
        try:
            status = booking.get('status')
            if status not in ['approved', 'rejected']:
                return

            # Note: Renter receives the update
            renter_id = booking.get('renterId') or booking.get('tenantId')
            if not renter_id or renter_id.strip() == "":
                print(f"⚠️ Warning: Updated booking missing valid renterId. Data: {booking}")
                return

            user_doc = self.db.collection('users').document(renter_id).get()
            if user_doc.exists:
                token = user_doc.to_dict().get('fcmToken')
                if token:
                    self.send_push_notification(
                        token=token,
                        title="Visit Request Update",
                        body=f"Your visit request has been {status}",
                        data={"chatId": booking.get('chatId', '')}
                    )
        except Exception as e:
            print(f"❌ Error processing booking update: {str(e)}")

def run_watcher():
    watcher = NotificationWatcher()
    while True:
        if not watcher.initialized:
            watcher.try_initialize()
            if not watcher.initialized:
                time.sleep(30) # Wait 30 seconds before re-checking for the key
                continue
        
        try:
            watcher.start_watching()
            # Keep the thread alive
            while True:
                time.sleep(60)
        except Exception as e:
            print(f"❌ Watcher crashed: {str(e)}. Restarting in 10s...")
            time.sleep(10)

def start_notification_service():
    thread = threading.Thread(target=run_watcher, daemon=True)
    thread.start()
    return thread
