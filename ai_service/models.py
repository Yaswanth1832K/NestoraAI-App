from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    role = Column(String) # tenant / owner
    phone = Column(String)

class Property(Base):
    __tablename__ = "properties"
    id = Column(String, primary_key=True, index=True)
    owner_id = Column(String, ForeignKey("users.id"))
    title = Column(String)
    price = Column(Float)
    city = Column(String)
    address = Column(Text)
    description = Column(Text)
    images = Column(Text) # Comma separated URLs
    amenities = Column(Text) # Comma separated

class VisitRequest(Base):
    __tablename__ = "visit_requests"
    id = Column(String, primary_key=True, index=True)
    property_id = Column(String, ForeignKey("properties.id"))
    tenant_id = Column(String, ForeignKey("users.id"))
    date = Column(String)
    time = Column(String)
    status = Column(String, default="pending") # pending / approved / rejected

class Message(Base):
    __tablename__ = "messages"
    id = Column(String, primary_key=True, index=True)
    sender_id = Column(String, ForeignKey("users.id"))
    receiver_id = Column(String, ForeignKey("users.id"))
    property_id = Column(String, ForeignKey("properties.id"))
    content = Column(Text)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

class Payment(Base):
    __tablename__ = "payments"
    id = Column(String, primary_key=True, index=True)
    tenant_id = Column(String, ForeignKey("users.id"))
    owner_id = Column(String, ForeignKey("users.id"))
    amount = Column(Float)
    status = Column(String) # success / pending
    date = Column(DateTime, default=datetime.datetime.utcnow)

class SavedProperty(Base):
    __tablename__ = "saved_properties"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    property_id = Column(String, ForeignKey("properties.id"))

class Coupon(Base):
    __tablename__ = "coupons"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    type = Column(String) # percent / amount / service
    title = Column(String)
    discount_percent = Column(Float, nullable=True)
    discount_amount = Column(Float, nullable=True)
    service_type = Column(String, nullable=True)
    expiry_date = Column(DateTime)
    is_used = Column(Integer, default=0) # 0 for false, 1 for true
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
