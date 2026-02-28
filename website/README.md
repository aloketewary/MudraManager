# Mudra Manager Website

Simple, modern landing page for Mudra Manager app.

## 🚀 Quick Deploy

### Option 1: GitHub Pages (Free)

1. **Create `gh-pages` branch**:
   ```bash
   git checkout -b gh-pages
   git add website/
   git commit -m "Add website"
   git push origin gh-pages
   ```

2. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Source: `gh-pages` branch
   - Folder: `/website`
   - Save

3. **Access**: `https://YOUR_USERNAME.github.io/mudra_manager/`

### Option 2: Netlify (Free)

1. Go to [Netlify](https://netlify.com)
2. Drag & drop the `website` folder
3. Done! Get instant URL

### Option 3: Vercel (Free)

1. Go to [Vercel](https://vercel.com)
2. Import repository
3. Set build directory to `website`
4. Deploy

### Option 4: Firebase Hosting (Free)

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Select website folder
firebase deploy
```

## 📝 Customize

### Update Play Store Link

Edit `index.html` and replace:
```html
https://play.google.com/store/apps/details?id=com.mudramanager.app
```

With your actual Play Store URL.

### Change Colors

Edit `style.css`:
```css
:root {
    --primary: #6366f1;  /* Your brand color */
}
```

### Add Screenshots

1. Take app screenshots
2. Add to `website/images/` folder
3. Update HTML to show screenshots

## 🎨 Features

- ✅ Responsive design (mobile & desktop)
- ✅ Modern UI with smooth animations
- ✅ Play Store download button
- ✅ Feature showcase
- ✅ Fast loading
- ✅ SEO optimized

## 📱 Preview Locally

```bash
cd website
python3 -m http.server 8000
# Open http://localhost:8000
```

Or use VS Code Live Server extension.

## 🔗 Custom Domain

### GitHub Pages:
1. Add `CNAME` file with your domain
2. Configure DNS:
   - Type: CNAME
   - Name: www
   - Value: YOUR_USERNAME.github.io

### Netlify/Vercel:
- Add custom domain in dashboard
- Follow DNS instructions

## 📊 Analytics

Add Google Analytics:
```html
<!-- Add before </head> in index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_ID');
</script>
```

## 🎯 Next Steps

1. Deploy website
2. Update Play Store link
3. Add app screenshots
4. Set up custom domain (optional)
5. Add analytics (optional)
