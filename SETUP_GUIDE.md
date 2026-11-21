# DiaCare - Complete Setup & Installation Guide

Welcome to **DiaCare**, a production-quality full-stack diabetes patient management application designed for patients of all ages, including elderly users.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend** | Flutter 3.x / Dart 3.x | Material 3, Clean Architecture, Null-Safety |
| **Backend** | PHP 8 REST API | PDO Prepared Statements, HMAC-SHA256 JWT, JSON Responses |
| **Database** | MySQL / MariaDB (XAMPP) | InnoDB, Foreign Keys, Indexes, Indian Food Seeds |
| **State Management**| Provider | `AuthProvider`, `ProfileProvider`, `SugarProvider`, `CalorieProvider`, `ReminderProvider`, `ThemeProvider` |
| **Alarms & Alerts** | `flutter_local_notifications` + `timezone` | Scheduled reminders + urgent hypoglycemia/hyperglycemia alerts |
| **Charts** | `fl_chart` | Interactive glucose line chart & weekly calorie bars |

---

## 📂 Project Directory Structure

```text
c:\xampp\htdocs\diacare_full_stack\
├── database/
│   ├── diacare_db.sql                     <-- Complete MySQL database schema & seed data
│   └── init_db.php                        <-- Automated PHP database installer
├── backend/                               <-- PHP 8 REST API (accessible via http://localhost/diacare_api)
│   ├── config/
│   │   └── db.php                         <-- PDO connection (auto-detects port 3305 & 3306)
│   ├── utils/
│   │   ├── jwt.php                        <-- HMAC-SHA256 JWT token generation & auth guard
│   │   ├── response.php                   <-- Standardized JSON response & CORS handler
│   │   └── validation.php                 <-- BMI calculation & glucose classification
│   ├── api/
│   │   ├── auth/                          <-- register, login, forgot-password, change-password, delete-account
│   │   ├── profile/                       <-- get, update profile & BMI
│   │   ├── sugar/                         <-- add reading, get analytics, delete reading
│   │   ├── calories/                      <-- log meal, get daily summary, food catalog (Indian foods)
│   │   ├── reminders/                     <-- get, add, update, toggle, delete reminders
│   │   └── tips/                          <-- daily curated diabetes health tip
│   ├── test_api.php                       <-- Automated backend test suite
│   ├── index.php                          <-- Root API status & documentation
│   └── DiaCare_API_Postman_Collection.json <-- Ready-to-import Postman collection
├── frontend/                              <-- Complete Flutter Mobile Application
│   ├── android/app/src/main/AndroidManifest.xml <-- Permissions: Alarms, Notifications, Internet, Cleartext
│   ├── pubspec.yaml                       <-- All dependencies configured
│   └── lib/
│       ├── core/                          <-- constants, theme, api_service, notification_service
│       ├── models/                         <-- user, profile, sugar, meal, food, reminder, health_tip
│       ├── providers/                      <-- auth, profile, sugar, calorie, reminder, theme
│       ├── widgets/                        <-- custom_button, custom_text_field, status_badge, danger_alert_dialog
│       ├── screens/
│       │   ├── onboarding/                <-- splash_screen, onboarding_screen
│       │   ├── auth/                      <-- login_screen, register_screen, forgot_password_screen
│       │   ├── profile/                   <-- personal_details_screen, profile_screen
│       │   ├── home/                      <-- home_dashboard_screen
│       │   ├── tracker/                   <-- sugar_tracker_screen, add_sugar_screen
│       │   ├── calories/                  <-- calorie_tracker_screen, add_meal_screen
│       │   ├── reminders/                 <-- reminders_screen, add_reminder_screen
│       │   └── main_navigation_screen.dart <-- 5-tab bottom navigation
│       └── main.dart                      <-- App entry point
└── SETUP_GUIDE.md                         <-- This guide
```

---

## 🚀 Step-by-Step Installation

### Step 1: Start XAMPP (Apache & MySQL)
1. Open the **XAMPP Control Panel**.
2. Click **Start** on **Apache** (running on port `80`).
3. Click **Start** on **MySQL** (configured on port `3305` or `3306`).

---

### Step 2: Import the Database (`diacare_db.sql`)

#### Option A: Automatic via Command Line (Recommended)
Open PowerShell and run:
```powershell
cd c:\xampp\htdocs\diacare_full_stack
php database/init_db.php
```
*This connects automatically to your running MySQL instance, drops older tables if any, creates the complete schema, and populates 34+ Indian foods and health tips.*

#### Option B: Via phpMyAdmin Web Interface
1. Open your browser and visit: `http://localhost/phpmyadmin/`
2. Click **New** in the left sidebar and create database: `diacare_db` (Collation: `utf8mb4_unicode_ci`).
3. Select `diacare_db` and click the **Import** tab.
4. Click **Choose File** and select:
   `c:\xampp\htdocs\diacare_full_stack\database\diacare_db.sql`
5. Click **Go** at the bottom to execute the import.

---

### Step 3: Verify the PHP Backend API

The backend is located directly in `c:\xampp\htdocs\diacare_full_stack\backend` and is accessible under Apache at:
`http://localhost/diacare_full_stack/backend/`

1. Open your web browser and navigate to:
   ```text
   http://localhost/diacare_full_stack/backend/index.php
   ```
   You should see:
   ```json
   {
       "status": "success",
       "message": "DiaCare Diabetes Patient Management REST API is running.",
       "data": {
           "app": "DiaCare",
           "version": "1.0.0",
           "status": "online",
           "db_connected": true
       }
   }
   ```

2. Run the automated backend test suite to verify all 12 endpoints:
   ```powershell
   cd c:\xampp\htdocs\diacare_full_stack
   php backend/test_api.php
   ```
   *Expected output: `ALL BACKEND API TESTS COMPLETED SUCCESSFULLY!`*

---

### Step 4: Configure API Base URL for Your Device

In `frontend/lib/core/constants.dart`, the base URL is configured to:
- **Physical Android Phone (Wi-Fi)**: `http://192.168.1.49/diacare_full_stack/backend`
- **Android Emulator**: `http://10.0.2.2/diacare_full_stack/backend`
- **Flutter Web / Windows**: `http://localhost/diacare_full_stack/backend`

---

### Step 5: Run the Flutter Application

1. Open a terminal and navigate to the `frontend` folder:
   ```powershell
   cd c:\xampp\htdocs\diacare_full_stack\frontend
   ```

2. Fetch Flutter dependencies:
   ```powershell
   flutter pub get
   ```

3. Launch on your desired device:
   - **Android Emulator / Device**:
     ```powershell
     flutter run
     ```
   - **Chrome Web**:
     ```powershell
     flutter run -d chrome
     ```
   - **Edge Web**:
     ```powershell
     flutter run -d edge
     ```

---

## 📱 App Walkthrough & Features

1. **Splash & Onboarding**:
   - Animated medical pulse logo.
   - 3 elderly-friendly onboarding slides explaining blood sugar logging, Indian calorie counting, and medicine reminders.
2. **Authentication**:
   - Register with Name, Email, Phone, Password.
   - Login with Email or Phone + password.
   - Password reset with a 6-digit verification code.
3. **Step-by-Step Personal Details Wizard**:
   - Step 1: Name, Age, DOB, Gender, Height, Weight with live **auto-calculated BMI** and clinical category badge.
   - Step 2: Diabetes Type (Type 1, Type 2, Gestational, Pre-diabetes), Year Diagnosed, Current Medicines, Allergies.
   - Step 3: Emergency contact name and phone, Doctor name and hospital, Daily calorie goal.
4. **Home Dashboard**:
   - Time-aware greeting ("Good Morning / Evening").
   - Quick-add buttons (`+ Sugar`, `+ Meal`, `+ Reminder`).
   - Latest blood sugar card with status color badge.
   - Today's calories progress ring.
   - Next scheduled medicine alarm card.
   - Curated daily diabetes tip.
   - Medical disclaimer banner.
5. **Blood Sugar Tracker**:
   - Interactive line chart using `fl_chart` with daily / weekly / monthly periods.
   - Average, Highest, Lowest statistical summary.
   - Automatic classification: Low (<70), Normal (70–140), High (>140).
   - **Emergency Alert**: If sugar is <70 mg/dL (hypoglycemia) or >250 mg/dL, an urgent alert dialog appears with the clinical 15-15 rule or hydration advice, and a one-tap button to call the patient's emergency contact!
6. **Calorie & Indian Food Tracker**:
   - Built-in search of common Indian foods (Idli, Dosa, Chapati, Rice, Dal, Sambar, Upma, Poha, Karela fry, etc.).
   - Serving quantity stepper with auto-calculated calories and carbs.
   - Circular progress ring showing remaining calories.
   - 7-day weekly bar chart.
7. **Medication & Checkup Alarms**:
   - Custom sound and vibration notifications in background.
   - Categories: Medicine, Sugar Check, Drink Water, Meal Time, Walk/Exercise, Doctor Appointment.
   - Instant toggle switch to activate/deactivate alarms.
8. **Profile & Settings**:
   - Profile summary with BMI pill.
   - Edit personal details anytime.
   - Dark mode toggle.
   - Change password and logout.
   - Permanent delete account with safety confirmation.

---

## ⚕️ Medical Disclaimer
> "DiaCare is for tracking only and does not replace professional medical advice. Always consult your doctor for medical decisions."
