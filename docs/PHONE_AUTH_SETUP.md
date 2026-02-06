# Phone Auth (Production) Setup

The app uses Firebase Phone Authentication with reCAPTCHA Enterprise. Configure the following in your Firebase/Google Cloud project.

## Requirements

1. **Google Cloud Console** → your Firebase project → **Billing**: link a billing account.
2. **APIs & Services** → **Library**: enable **reCAPTCHA Enterprise API**.
3. **Security** → **reCAPTCHA Enterprise**: create an **Android** key:
   - Add package name: `com.findmytutor.app`
   - Add your app’s SHA-1 (from `keytool` or Android Studio signing report).
4. **Firebase Console** → **Authentication** → **Sign-in method** → **Phone**: ensure Phone sign-in is enabled.

After this, real SMS OTP will work for all users.
