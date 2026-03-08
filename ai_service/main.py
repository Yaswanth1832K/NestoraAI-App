import os
import re
import traceback
import datetime
from typing import List, Optional

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

import google.generativeai as genai
from notifications import start_notification_service, NotificationWatcher
from models import Base, User, Property, VisitRequest, Message, Payment, SavedProperty
from firebase_admin import messaging, firestore

# Database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./nestora.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Nestora AI & CRUD Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

import time
from fastapi import Request

# Start the real-time notification watcher
start_notification_service()

# ── Logging Middleware ─────────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = (time.time() - start_time) * 1000
    formatted_process_time = "{0:.2f}ms".format(process_time)
    client_host = request.client.host if request.client else "unknown"
    print(f"🌐 [{request.method}] {request.url.path} - {response.status_code} ({formatted_process_time}) | IP: {client_host}")
    return response

@app.get("/health")
def health_check():
    return {
        "status": "server running",
        "timestamp": datetime.datetime.now().isoformat(),
        "ai_ready": is_gemini_ready
    }

# Configure Gemini API
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyB1YL5hTHr2I3Fpys1Jr4rDW2CkP8nwdbQ")
is_gemini_ready = False
try:
    genai.configure(api_key=GEMINI_API_KEY)
    is_gemini_ready = True
    print(f"✅ Gemini API Key configured: {GEMINI_API_KEY[:4]}...{GEMINI_API_KEY[-4:]}")
except Exception as e:
    print(f"❌ Error configuring Gemini: {e}")

# ── Pydantic Schemas ──────────────────────────────────────────

class PropertySchema(BaseModel):
    id: str
    owner_id: str
    title: str
    price: float
    city: str
    address: str
    description: str
    images: Optional[str] = ""
    amenities: Optional[str] = ""

class VisitSchema(BaseModel):
    id: str
    property_id: str
    tenant_id: str
    date: str
    time: str
    status: Optional[str] = "pending"

class MessageSchema(BaseModel):
    id: str
    sender_id: str
    receiver_id: str
    property_id: str
    content: str

class PaymentSchema(BaseModel):
    id: str
    tenant_id: str
    owner_id: str
    amount: float
    status: str

class CouponSchema(BaseModel):
    id: str
    user_id: str
    type: str
    title: str
    discount_percent: Optional[float] = None
    discount_amount: Optional[float] = None
    service_type: Optional[str] = None
    expiry_date: str

class CouponValidateRequest(BaseModel):
    coupon_id: str
    user_id: str

class SearchQuery(BaseModel):
    query: str

class PriceRequest(BaseModel):
    city: str
    sqft: float
    bedrooms: int
    bathrooms: int

# Global helper for FCM (assuming firebase_admin already initialized in notifications.py)
def send_fcm_notification(user_id: str, title: str, body: str, data: dict = None):
    try:
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        if user_doc.exists:
            token = user_doc.to_dict().get('fcmToken')
            if token:
                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data=data or {},
                    token=token
                )
                messaging.send(message)
                print(f"🚀 Sent FCM to {user_id}")
    except Exception as e:
        print(f"❌ FCM Error ({user_id}): {e}")

# ── AI Endpoints ──────────────────────────────────────────────

@app.get("/")
def home():
    return {
        "status": "AI & CRUD service running",
        "database": "SQLite Connected",
        "ai_ready": is_gemini_ready
    }

@app.post("/search/natural-language")
def natural_language_search(data: SearchQuery):
    text = data.query.lower()
    bedrooms = None
    max_price = None
    keywords = []

    bhk_match = re.search(r'(\d+)\s*bhk', text)
    if bhk_match:
        bedrooms = int(bhk_match.group(1))

    price_match = re.search(r'(under|below)\s*(\d+)', text)
    if price_match:
        max_price = int(price_match.group(2))

    if "college" in text: keywords.append("college")
    if "student" in text: keywords.append("student")

    return {
        "success": True,
        "filters": {"bedrooms": bedrooms, "max_price": max_price, "keywords": keywords}
    }

@app.post("/price/predict")
def predict_price(data: PriceRequest):
    # simple heuristic model (acceptable for academic project)
    base_price = 4000
    bedroom_factor = data.bedrooms * 3500
    size_factor = data.sqft * 8
    bathroom_factor = data.bathrooms * 1500
    city_multiplier = 1.0
    if data.city.lower() in ["bangalore", "bengaluru"]: city_multiplier = 1.8
    elif data.city.lower() in ["chennai"]: city_multiplier = 1.5
    elif data.city.lower() in ["coimbatore"]: city_multiplier = 1.2
    
    predicted = (base_price + bedroom_factor + size_factor + bathroom_factor) * city_multiplier
    return {"predicted_price": int(predicted)}

# ── CRUD Endpoints ────────────────────────────────────────────

# 1. Properties
@app.post("/properties")
def create_property(prop: PropertySchema, db: Session = Depends(get_db)):
    db_prop = Property(**prop.dict())
    db.add(db_prop)
    db.commit()
    db.refresh(db_prop)
    return db_prop

@app.get("/properties")
def get_properties(city: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(Property)
    if city:
        query = query.filter(Property.city == city)
    return query.all()

@app.put("/properties/{prop_id}")
def update_property(prop_id: str, prop: PropertySchema, db: Session = Depends(get_db)):
    db_prop = db.query(Property).filter(Property.id == prop_id).first()
    if not db_prop:
        raise HTTPException(status_code=404, detail="Property not found")
    
    for key, value in prop.dict().items():
        setattr(db_prop, key, value)
    
    db.commit()
    db.refresh(db_prop)
    return db_prop

@app.delete("/properties/{prop_id}")
def delete_property(prop_id: str, db: Session = Depends(get_db)):
    prop = db.query(Property).filter(Property.id == prop_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    db.delete(prop)
    db.commit()
    return {"message": "Deleted"}

# 2. Visit Requests
@app.post("/visits")
def create_visit(visit: VisitSchema, db: Session = Depends(get_db)):
    db_visit = VisitRequest(**visit.dict())
    db.add(db_visit)
    db.commit()
    
    # Notify Owner
    prop = db.query(Property).filter(Property.id == db_visit.property_id).first()
    if prop:
        send_fcm_notification(
            user_id=prop.owner_id,
            title="New Visit Request",
            body=f"Someone wants to visit your property: {prop.title}",
            data={"click_action": "OWNER_REQUESTS", "type": "booking"}
        )
    return db_visit

@app.get("/visits")
def get_visits(user_id: str, db: Session = Depends(get_db)):
    return db.query(VisitRequest).filter((VisitRequest.tenant_id == user_id) | (VisitRequest.property_id.in_(db.query(Property.id).filter(Property.owner_id == user_id)))).all()

# 3. Messages
@app.post("/messages")
def send_message(msg: MessageSchema, db: Session = Depends(get_db)):
    db_msg = Message(**msg.dict())
    db.add(db_msg)
    db.commit()
    return db_msg

@app.get("/messages")
def get_messages(user_id: str, db: Session = Depends(get_db)):
    return db.query(Message).filter((Message.sender_id == user_id) | (Message.receiver_id == user_id)).all()

# 4. Payments
@app.post("/payments")
def create_payment(pay: PaymentSchema, db: Session = Depends(get_db)):
    db_pay = Payment(**pay.dict())
    db.add(db_pay)
    db.commit()
    
    # Notify tenant and owner
    send_fcm_notification(
        user_id=pay.tenant_id,
        title="Payment Successful",
        body=f"Your payment of ₹{pay.amount} was processed.",
        data={"click_action": "RENT_PAYMENTS", "type": "success"}
    )
    send_fcm_notification(
        user_id=pay.owner_id,
        title="Payment Received",
        body=f"You received ₹{pay.amount} rent payment.",
        data={"click_action": "OWNER_DASHBOARD", "type": "success"}
    )
    return db_pay

@app.get("/payments")
def get_payments(user_id: str, db: Session = Depends(get_db)):
    # Returns payments where user is tenant or owner
    return db.query(Payment).filter((Payment.tenant_id == user_id) | (Payment.owner_id == user_id)).all()

# 5. Coupons
from models import Coupon

@app.post("/coupons/create")
def create_coupon(data: CouponSchema, db: Session = Depends(get_db)):
    # Convert expiry_date string to datetime object
    try:
        expiry = datetime.datetime.fromisoformat(data.expiry_date.replace('Z', '+00:00'))
    except Exception:
        expiry = datetime.datetime.utcnow() + datetime.timedelta(days=30)
        
    db_coupon = Coupon(
        id=data.id,
        user_id=data.user_id,
        type=data.type,
        title=data.title,
        discount_percent=data.discount_percent,
        discount_amount=data.discount_amount,
        service_type=data.service_type,
        expiry_date=expiry,
        is_used=0
    )
    db.add(db_coupon)
    db.commit()
    db.refresh(db_coupon)
    
    # Notify User
    send_fcm_notification(
        user_id=data.user_id,
        title="New Reward Earned! 🎁",
        body=f"You've received a coupon: {data.title}",
        data={"click_action": "MY_COUPONS", "type": "reward"}
    )
    return db_coupon

@app.get("/coupons/{user_id}")
def get_user_coupons(user_id: str, db: Session = Depends(get_db)):
    return db.query(Coupon).filter(Coupon.user_id == user_id).all()

@app.post("/coupons/validate")
def validate_coupon(data: CouponValidateRequest, db: Session = Depends(get_db)):
    coupon = db.query(Coupon).filter(Coupon.id == data.coupon_id, Coupon.user_id == data.user_id).first()
    
    if not coupon:
        return {"valid": False, "message": "Coupon not found"}
    
    if coupon.is_used == 1:
        return {"valid": False, "message": "Coupon already used"}
    
    if coupon.expiry_date < datetime.datetime.utcnow():
        return {"valid": False, "message": "Coupon expired"}
    
    return {
        "valid": True,
        "discount_percent": coupon.discount_percent,
        "discount_amount": coupon.discount_amount,
        "type": coupon.type,
        "service_type": coupon.service_type
    }

@app.post("/coupons/use")
def use_coupon(data: CouponValidateRequest, db: Session = Depends(get_db)):
    coupon = db.query(Coupon).filter(Coupon.id == data.coupon_id, Coupon.user_id == data.user_id).first()
    
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    
    if coupon.is_used == 1:
        raise HTTPException(status_code=400, detail="Coupon already used")
    
    coupon.is_used = 1
    db.commit()
    return {"success": True, "message": "Coupon marked as used"}

# ── Gemini Shared Logic ───────────────────────────────────────

class PropertyChatRequest(BaseModel):
    question: str
    title: str
    description: str
    price: float
    city: str
    bedrooms: int
    bathrooms: int
    sqft: float

@app.post("/chat/property")
def chat_about_property(data: PropertyChatRequest):
    try:
        model = genai.GenerativeModel('gemini-flash-latest')
        prompt = f"""You are an AI real estate assistant.
Property: {data.title} in {data.city} (₹{data.price}/mo). {data.sqft} sqft, {data.bedrooms} BHK.
Desc: {data.description}
User Question: {data.question}
Answer concisely (2 sentences)."""
        response = model.generate_content(prompt)
        return {"success": True, "reply": response.text}
    except Exception as e:
        return {"success": False, "reply": f"Error: {str(e)}"}

class RecommendationRequest(BaseModel):
    user_preferences: str
    available_properties: str 

@app.post("/recommendations")
def get_recommendations(data: RecommendationRequest):
    try:
        model = genai.GenerativeModel('gemini-flash-latest')
        prompt = f"""Recommend top 3 properties based on:
Prefs: {data.user_preferences}
Props: {data.available_properties}
Return IDs and 1 sentence why."""
        response = model.generate_content(prompt)
        return {"success": True, "recommendations": response.text}
    except Exception as e:
        return {"success": False, "error": str(e)}

