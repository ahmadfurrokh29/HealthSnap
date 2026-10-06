# HealthSnap 🏥📱
### Digital Medical Records Management App
website link: https://healthsnapweb.netlify.app/
HealthSnap is a Flutter-based mobile application that digitizes 
patient medical records in Pakistan, eliminating dependency on 
paper-based prescriptions and lab reports through OCR scanning, 
AI summaries, and QR-based doctor sharing.

---

## 🚩 Problem Statement

In Pakistan, patients manage prescriptions, lab reports, and medical 
history entirely on paper. This leads to:
- Lost or damaged reports
- Doctors unable to access previous history
- Duplicate medical tests being ordered
- Increased consultation time
- Disorganized records

---

## 💡 Solution

HealthSnap digitizes medical records and makes them instantly 
accessible to both patients and doctors through a secure, 
role-based mobile application.

---

## 👥 User Modules

### 🧑‍⚕️ Patient App
- Scan & upload lab reports, prescriptions, medical history
- OCR-based automatic data extraction
- AI-generated report summaries
- Dynamic QR code generation for doctor sharing
- Dashboard with total records & reports overview

### 👨‍⚕️ Doctor App
- Scan patient QR code to access records instantly
- View medical history, diagnoses, medicines, test values
- Appointment management
- Session-based access (auto-revoked after session ends)

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 Authentication | Firebase Auth with role-based access (Patient/Doctor) |
| 📄 OCR Scanning | Extracts doctor name, diagnosis, medicines, test values |
| 🤖 AI Summaries | Auto-generated summaries for each uploaded report |
| 📱 QR Sharing | Dynamic QR codes for secure, temporary doctor access |
| 🔒 Session Control | Doctor access auto-revoked after consultation ends |
| ☁️ Cloud Storage | Cloudinary for images, Firestore for structured data |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Image Storage | Cloudinary |
| OCR & AI | OCR API + Google Gemini AI |
| QR System | Flutter QR Generator & Scanner |
| Version Control | GitHub |
| Design | Google Stitch |

---

