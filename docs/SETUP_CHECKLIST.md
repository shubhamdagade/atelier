# ✅ Google Maps Integration - User Setup Checklist

## Pre-Deployment Checklist

### Step 1: Get Google Maps API Key
- [ ] Go to https://console.cloud.google.com/
- [ ] Create new project or select existing
- [ ] Search for "Maps JavaScript API" and enable it
- [ ] Search for "Places API" and enable it  
- [ ] Search for "Geocoding API" and enable it
- [ ] Go to Credentials → Create Credentials → API Key
- [ ] Copy the generated API key

### Step 2: Restrict API Key
- [ ] In Credentials, click on your API key
- [ ] Under "Application restrictions" → Select "HTTP referrers"
- [ ] Add your domain(s):
  - [ ] Local: `http://localhost:5173`
  - [ ] Dev: `https://cautious-spoon-r49494jq9gv9cv56-5174.app.github.dev`
  - [ ] Production: (add when deployed)
- [ ] Under "API restrictions" → Restrict to:
  - [ ] Maps JavaScript API
  - [ ] Places API
  - [ ] Geocoding API

### Step 3: Add to Environment
- [ ] Copy `.env.example` to `.env` (if not already done)
- [ ] Find line: `VITE_GOOGLE_MAPS_API_KEY=`
- [ ] Paste your API key after the `=`
- [ ] Save `.env` file
- [ ] **DO NOT commit `.env` to git**

### Step 4: Restart Development Server
- [ ] Stop current `npm run dev` (Ctrl+C)
- [ ] Run: `npm run dev`
- [ ] Wait for compilation to complete

### Step 5: Test Integration
- [ ] Open application in browser
- [ ] Log in to application
- [ ] Click "Create New Project" (on L1 Dashboard)
- [ ] Scroll to "Location" section
- [ ] Click "Show Google Map" button
- [ ] Verify map appears with marker in Mumbai
- [ ] Test search functionality:
  - [ ] Type "Times Square New York" in search box
  - [ ] Select from suggestions
  - [ ] Verify map centers on location
  - [ ] Verify coordinates populate
- [ ] Test click placement:
  - [ ] Click on map at different location
  - [ ] Verify marker moves
  - [ ] Verify coordinates update
  - [ ] Verify address is reverse-geocoded
- [ ] Test drag functionality:
  - [ ] Drag marker to new position
  - [ ] Verify coordinates update
  - [ ] Verify address updates
- [ ] Verify auto-save:
  - [ ] Change another field (Project name)
  - [ ] Check browser console (no errors)
  - [ ] Refresh page
  - [ ] Verify all data persisted

### Step 6: Monitor Costs
- [ ] Go to Google Cloud Console
- [ ] Check Billing section for usage
- [ ] Set up billing alerts (optional but recommended)
  - [ ] Alert threshold: $10/month
- [ ] Monthly check costs under free tier for development

## Troubleshooting Checklist

### Map Not Loading
- [ ] Check `.env` file has API key
- [ ] Check API key is not empty
- [ ] Verify spaces/quotes aren't added around key
- [ ] Open browser DevTools → Console tab
- [ ] Look for error messages
- [ ] Check that Maps JavaScript API is enabled
- [ ] Try restarting dev server

### Search Not Working
- [ ] Verify Places API is enabled in Google Cloud Console
- [ ] Verify domain is in API key HTTP referrer restrictions
- [ ] Open DevTools → Console tab
- [ ] Look for "Failed to load Places" or similar errors
- [ ] Try restarting dev server

### Coordinates Not Updating
- [ ] Click marker to verify it responds
- [ ] Try dragging marker
- [ ] Check browser console for errors
- [ ] Verify reverse geocoding works (address should populate)
- [ ] Check that auto-save is working (check Network tab)

### CORS Error
- [ ] Add exact domain to API key restrictions
- [ ] Include https:// or http:// in domain
- [ ] Don't include trailing slash
- [ ] Restart dev server

### "Loading..." Forever
- [ ] Check API key in `.env` is correct
- [ ] Verify all three APIs are enabled
- [ ] Check domain restrictions are correct
- [ ] Look for error messages in console
- [ ] Try clearing browser cache and reloading

## Features Verification Checklist

### Core Features
- [ ] Map displays on "Show Google Map"
- [ ] Map hides on "Hide Google Map"
- [ ] Initial location defaults to Mumbai
- [ ] Existing latitude/longitude values shown on map

### Search Functionality
- [ ] Search box accepts text input
- [ ] Autocomplete suggestions appear while typing
- [ ] Clicking suggestion updates map
- [ ] Address field populates
- [ ] Coordinates fields populate
- [ ] Location auto-saves to database

### Click Placement
- [ ] Can click on map to place marker
- [ ] Marker moves to clicked position
- [ ] Coordinates update immediately
- [ ] Address is reverse-geocoded
- [ ] Changes auto-save to database

### Drag Adjustment
- [ ] Can drag marker across map
- [ ] Coordinates update on drag end
- [ ] Address reverse-geocodes after drag
- [ ] Changes auto-save to database

### Map Controls
- [ ] Can zoom in/out
- [ ] Can pan around map
- [ ] Street view control visible
- [ ] Fullscreen control available

### Data Persistence
- [ ] Project data saves on location change
- [ ] Data persists after page refresh
- [ ] Data visible when editing project again
- [ ] Database query returns correct coordinates

## Performance Checklist

- [ ] Map loads within 2-3 seconds
- [ ] No console errors or warnings
- [ ] Search responds smoothly to typing
- [ ] Marker drag is smooth and responsive
- [ ] Page doesn't freeze during operations
- [ ] Auto-save doesn't cause visible lag

## Security Checklist

- [ ] API key not visible in source code
- [ ] API key not committed to git (check .gitignore)
- [ ] `.env` file in `.gitignore`
- [ ] Domain restrictions enabled
- [ ] API restrictions set to needed services only
- [ ] No sensitive data logged in console

## Deployment Preparation

### Before Pushing to Production
- [ ] Add production domain to API key restrictions
- [ ] Set up `.env` on production server
- [ ] Test on production domain
- [ ] Monitor Google Cloud costs
- [ ] Set up billing alerts
- [ ] Document API key rotation process
- [ ] Create backup of API key

### For Team Members
- [ ] Share setup instructions from README.md
- [ ] Share Google Maps API key (securely)
- [ ] Add production domain to API key (once deployed)
- [ ] Share `.env.example` path
- [ ] Document troubleshooting steps

## Documentation Files Created

- [X] `/docs/google-maps-integration.md` - Detailed guide
- [X] `/docs/google-maps-quick-reference.md` - Quick reference
- [X] `/docs/IMPLEMENTATION_COMPLETE.md` - Implementation summary
- [X] `/README.md` - Updated with setup instructions

## Files Modified

- [X] `src/components/GoogleMapComponent.jsx` - NEW (177 lines)
- [X] `src/pages/ProjectInput.jsx` - UPDATED (import + integration)
- [X] `.env.example` - UPDATED (added VITE_GOOGLE_MAPS_API_KEY)
- [X] `README.md` - REWRITTEN (setup guide)

## Ready to Go! 🚀

Once you complete the above checklist:
1. ✅ Google Maps integration is fully functional
2. ✅ Location search works perfectly
3. ✅ Coordinates auto-populate correctly
4. ✅ Data persists to database
5. ✅ Ready for production deployment

**Questions or Issues?**
- See troubleshooting section above
- Check `/docs/google-maps-integration.md` for detailed guide
- Review console errors in browser DevTools
- Check `/docs/IMPLEMENTATION_COMPLETE.md` for technical details
