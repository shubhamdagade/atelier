# Google Maps Integration - Quick Reference

## What Was Added

### New Component: GoogleMapComponent.jsx
- Full-featured interactive map with search capability
- Drag-and-drop marker placement
- Click-to-place marker functionality
- Real-time coordinate updates
- Address autocomplete via Google Places API
- Reverse geocoding (coordinates → address)
- Responsive design with tips section

### Updated Files
1. **ProjectInput.jsx**
   - Added GoogleMapComponent import
   - Replaced placeholder map with functional component
   - Integrated auto-save for location, latitude, longitude

2. **.env.example**
   - Added VITE_GOOGLE_MAPS_API_KEY variable

3. **README.md**
   - Complete setup instructions
   - Google Maps API key obtaining guide
   - Environment variables documentation

4. **docs/google-maps-integration.md**
   - Comprehensive integration guide
   - Troubleshooting section
   - Cost considerations

## Quick Start

### 1. Get API Key (5 minutes)
```
Go to: https://console.cloud.google.com/
1. Create new project
2. Enable: Maps JavaScript API, Places API, Geocoding API
3. Create API Key in Credentials
4. Add domain restriction
```

### 2. Add to .env
```env
VITE_GOOGLE_MAPS_API_KEY=your_key_here
```

### 3. Restart Server
```bash
npm run dev
```

### 4. Test
- Go to Project Input page
- Click "Show Google Map"
- Search location or click on map
- See lat/long auto-populate

## Key Features

| Feature | Behavior |
|---------|----------|
| **Search** | Type address → select from suggestions → map centers on location |
| **Click to Place** | Click map → marker moves → coordinates update → address reverse-geocoded |
| **Drag Marker** | Drag marker → coordinates update → address reverse-geocoded |
| **Auto-Save** | All changes → auto-saved to database in real-time |
| **Reverse Geocoding** | Coordinates → address lookup (Google Geocoding API) |

## Component Props

```jsx
<GoogleMapComponent
  latitude="19.0760"           // Current latitude (string or number)
  longitude="72.8777"          // Current longitude (string or number)
  location="Mumbai, India"     // Current address (string)
  onLocationSelect={(address, lat, lng) => {
    // Called when user selects a location
    // address: formatted address string
    // lat: latitude (8 decimals)
    // lng: longitude (8 decimals)
  }}
/>
```

## API Requirements

**Must Enable:**
- ☑️ Maps JavaScript API - For the map widget
- ☑️ Places API - For address search/autocomplete
- ☑️ Geocoding API - For coordinates → address conversion

**Quotas (Free Tier):**
- Maps: 28,000 loads/day ✓ Free
- Places: Limited free tier, then ~$7/1K requests
- Geocoding: Limited free tier, then ~$5/1K requests

For development under free tier, no charge applies.

## File Locations

```
/src/
  components/
    GoogleMapComponent.jsx       ← NEW MAP COMPONENT
  pages/
    ProjectInput.jsx             ← UPDATED (uses GoogleMapComponent)
/docs/
  google-maps-integration.md     ← DETAILED GUIDE
/.env.example                    ← UPDATED (new var)
/README.md                       ← UPDATED (setup guide)
```

## Typical Workflow

1. User clicks "Show Google Map" button
2. User either:
   - **Option A**: Types address in search → selects from autocomplete
   - **Option B**: Clicks on map to place marker
   - **Option C**: Drags existing marker to adjust
3. Coordinates auto-populate: `latitude` & `longitude` fields
4. Address auto-populates: `location` field
5. All changes auto-save to database

## Styling

- Uses Tailwind CSS (same as rest of app)
- Lodha brand colors maintained
- Responsive design (works on mobile/tablet)
- Info section with user tips

## Default Location

- Maps center: Mumbai (19.0760, 72.8777)
- Can be customized via latitude/longitude props
- Persists user's selected location

## Browser Support

- Chrome/Edge: ✓ Full support
- Firefox: ✓ Full support
- Safari: ✓ Full support
- Mobile: ✓ Works with touch gestures

## Debugging Tips

1. **Check API Key**: `console.log(import.meta.env.VITE_GOOGLE_MAPS_API_KEY)`
2. **Check API Loading**: Look for "Google Maps API loaded" in console
3. **Check Domain**: Verify domain is in API key restrictions
4. **Network Tab**: Check for CORS errors or blocked requests
5. **Console Errors**: Look for auth or loading errors

## Common Issues

| Issue | Solution |
|-------|----------|
| Map doesn't load | Verify API key in .env, restart dev server |
| Search doesn't work | Enable Places API, add domain to restrictions |
| Coordinates not updating | Check console for geocoding errors |
| CORS error | Add domain to API key HTTP referrer restrictions |
| "Loading..." forever | Check API key validity and API enablement |

## Next Steps / Future Enhancements

- [ ] Multiple marker support (different buildings)
- [ ] Distance calculation between locations
- [ ] Site boundary drawing tools
- [ ] Nearby amenities overlay
- [ ] Traffic layer integration
- [ ] Route optimization display
