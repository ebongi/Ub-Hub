# Comprehensive Testing Guide for GoStudy Changes

This guide outlines how to verify and test the major features and architectural changes we've implemented.

## 1. Environment & Database Setup (Prerequisites)

Before testing, ensure your environment is correctly configured:

> [!IMPORTANT]
> **Supabase SQL Update**
> Run this in your Supabase SQL Editor to enable AI credits:
> ```sql
> ALTER TABLE profiles ADD COLUMN ai_credits INTEGER DEFAULT 5;
> ```

> [!IMPORTANT]
> **Credentials in .env**
> Ensure your `.env` file has valid keys:
> - `FAPSHI_API_USER` & `FAPSHI_API_KEY` (Get from [fapshi.com](https://fapshi.com))
> - `FAPSHI_ENV=sandbox` (Use `live` only for production)
> - `GEMINI_API_KEY` (For AI features)

---

## 2. Testing Application Identity (App ID Change)

Verify that the app now identifies as `com.ebongsume.gostudy`.

### Android
- Run: `flutter build apk --debug`
- Inspect the generated APK or install it on a device.
- Verify the package name is `com.ebongsume.gostudy`.

### Firebase (Manual Check)
- Open your app. If Firebase features (like Auth or Firestore) fail to load, ensure you have updated the **Package Name** in the Firebase Console and replaced `google-services.json`.

---

## 3. Testing Fapshi Payment Gateway

Test the "Direct Pay" (USSD Push) flow using Fapshi Sandbox.

1.  Navigate to **Settings > AI Credits & Plans**.
2.  Tap the **"FAPSHI TEST MODE"** button (100 XAF).
3.  Enter a valid Cameroonian phone number (e.g., `67XXXXXXX`).
4.  **Sandbox Behavior**: In Sandbox, Fapshi doesn't send a real USSD. You usually simulate success/failure in the Fapshi dashboard or via their test numbers.
5.  **Verify**: On success, your credit balance at the top should increase by 10.

---

## 4. Testing AI Credit System & Monetization

Verify that AI usage correctly consumes "fuel" (credits).

### Feature: AI Chatbot
1.  Open **AI Assistant**.
2.  Check your initial balance (should be 5).
3.  Send a message.
4.  **Verify**: After the response, your balance in the "AI Shop" should be 4.

### Feature: PDF Summary
1.  Open any PDF document.
2.  Tap the **Auto Awesome (Sparkles)** icon.
3.  **Verify**: This costs 3 credits. Your balance should decrease accordingly.

### Feature: "Out of Credits" Gate
1.  Use AI features until your balance reaches 0.
2.  Try to send another message or generate a Study Plan.
3.  **Verify**: The **"AI Credits Required"** dialog should appear, blocking access and offering a link to the shop.

---

## 5. Testing Permission Restrictions (Admin vs. User)

Verify that only you (the developer/admin) can create departments and courses.

### Test as a Regular User
1.  Log in with a standard account (Role: `viewer` or `contributor`).
2.  Go to **All Departments**.
    - **Verify**: The "+" (New Dept) button is **hidden**.
3.  Open any Department.
    - Tap the **"Upload"** button.
    - **Verify**: "Add New Course" is **missing** from the list.
    - **Verify**: "Upload Course Material" and "Past Question" are still **visible and working**.

### Test as an Administrator
1.  Go to your Supabase Dashboard and change your user's role to `admin` in the `profiles` table.
2.  Restart the app.
3.  **Verify**: All "+" buttons and "Add New Course" options are now **visible and functional**.

---

## 6. Build & Deployment Check

Run a full build to ensure no broken imports or configuration errors:

```bash
# Clean project
flutter clean
flutter pub get

# Test Build
flutter build apk --split-per-abi
```

If the build completes without errors, the Application ID and Gradle configurations are 100% correct.
