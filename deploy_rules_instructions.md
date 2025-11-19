# Deploy Firestore Security Rules

## Option 1: Using Firebase CLI (Recommended)

1. **Login to Firebase:**
   ```bash
   firebase login
   ```
   This will open a browser window for authentication.

2. **Initialize Firebase project (if not already done):**
   ```bash
   firebase init firestore
   ```
   - Select your existing project: `dmgrs-c983c`
   - Use existing `firestore.rules` file: Yes
   - Use existing `firestore.indexes.json` file: No (or Yes if you have one)

3. **Deploy the rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

## Option 2: Manual Deployment via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **dmgrs-c983c**
3. Navigate to: **Firestore Database** → **Rules** tab
4. Copy the entire contents of `firestore.rules` file
5. Paste into the rules editor
6. Click **"Publish"** button

## Verify Deployment

After deployment, try logging in again. The authentication should work properly.

