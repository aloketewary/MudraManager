# Website Deployment Instructions

## Files Created
- `docs/index.html` - Homepage
- `docs/privacy-policy.html` - Privacy Policy
- `docs/terms-conditions.html` - Terms & Conditions

## Deploy to GitHub Pages

### 1. Push to GitHub
```bash
git add docs/
git commit -m "Add website with privacy policy and terms"
git push origin main
```

### 2. Enable GitHub Pages
1. Go to your repository on GitHub
2. Click **Settings** → **Pages**
3. Under **Source**, select:
   - Branch: `main`
   - Folder: `/docs`
4. Click **Save**

### 3. Your Website URLs
After deployment (takes 1-2 minutes):
- Homepage: `https://YOUR_USERNAME.github.io/mudra_manager/`
- Privacy Policy: `https://YOUR_USERNAME.github.io/mudra_manager/privacy-policy.html`
- Terms: `https://YOUR_USERNAME.github.io/mudra_manager/terms-conditions.html`

### 4. Update App Links
Replace `YOUR_USERNAME` in `lib/screens/profile/about_app.dart` with your actual GitHub username.

## Use in Play Store
Use the privacy policy URL in your Play Store listing:
```
https://YOUR_USERNAME.github.io/mudra_manager/privacy-policy.html
```

## App Integration
The app now has clickable links in the About screen:
- Privacy Policy → Opens in browser
- Terms & Conditions → Opens in browser
- Contact Us → Opens email client

## Testing
After deployment, test the links:
1. Open the app
2. Go to Profile → About
3. Tap "Privacy Policy" - should open browser
4. Tap "Terms & Conditions" - should open browser
5. Tap "Contact Us" - should open email

Done! Your website is live and integrated with the app.
