# Google Maps Integration Guide

## Overview
Google Maps has been integrated into the ProjectInput page for location search and coordinate selection. Users can now search for addresses, click on the map to place markers, and automatically populate latitude/longitude coordinates.

## Features

### 1. Location Search
- Type address in the search box to find locations
- Autocomplete suggestions from Google Places API
- Formatted address display

### 2. Interactive Map
- Drag markers to adjust location
- Click on map to place new markers
- Real-time coordinate updates
- Zoom and pan controls
- Street view available

### 3. Coordinate Population
- Automatic latitude/longitude population from map interaction
- Reverse geocoding to get address from coordinates
- 8 decimal precision for accuracy

### 4. Auto-Save
- All location changes auto-save to database
- Address, latitude, and longitude fields update in real-time

## Setup

### 1. Get Google Maps API Key

Visit [Google Cloud Console](https://console.cloud.google.com/):

1. Create a new project
2. Enable these APIs:
   - **Maps JavaScript API** - For interactive map
   - **Places API** - For address search and autocomplete
   - **Geocoding API** - For reverse geocoding (converting coordinates to addresses)

3. Create API Key:
   - Go to Credentials → Create Credentials → API Key
   - Copy the key

4. Configure restrictions:
   - In Credentials, click on your API key
   - Under "Application restrictions", select "HTTP referrers"
   - Add your domain (e.g., `cautious-spoon-r49494jq9gv9cv56-5174.app.github.dev`)
   - Under "API restrictions", select "Restrict key" and choose the APIs above

### 2. Add to Environment

Update `.env` file:
```env
VITE_GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

### 3. Restart Development Server

```bash
npm run dev
```

## How to Use

1. In ProjectInput page, click "Show Google Map" button
2. Use search box to find location or manually click on map
3. Drag marker to fine-tune location if needed
4. Coordinates auto-populate in the form
5. Data auto-saves to database

## Component Details

### GoogleMapComponent
**Location**: `src/components/GoogleMapComponent.jsx`

**Props**:
- `latitude` (string): Current latitude
- `longitude` (string): Current longitude
- `location` (string): Current address
- `onLocationSelect` (function): Callback when location is selected

**Features**:
- Dynamic Google Maps API loading
- Error handling for failed API loads
- Marker drag functionality
- Click-to-place markers
- Reverse geocoding
- Search box with Places autocomplete
- Tips section for user guidance

### Integration in ProjectInput
**Location**: `src/pages/ProjectInput.jsx`

**Usage**:
```jsx
<GoogleMapComponent
  latitude={projectData.latitude}
  longitude={projectData.longitude}
  location={projectData.location}
  onLocationSelect={(address, lat, lng) => {
    // Update project data and auto-save
  }}
/>
```

## API Integration

### Google Maps JavaScript API
- Loads dynamically on component mount
- Uses libraries: `places` for autocomplete

### Reverse Geocoding
- Converts map coordinates to addresses
- Called when marker is placed via click or drag

### Places Autocomplete
- Provides address suggestions as user types
- Returns formatted_address and geometry

## Troubleshooting

### Map Not Loading
1. Check API key is correctly set in `.env`
2. Verify Google Cloud APIs are enabled
3. Check domain is whitelisted in API key restrictions
4. Look at browser console for CORS errors

### Search Not Working
1. Ensure Places API is enabled
2. Check API key has Places API restriction
3. Verify search box reference is properly connected

### Coordinates Not Updating
1. Check console for geocoding errors
2. Verify lat/long inputs are accepting numbers
3. Check auto-save network requests in dev tools

## Cost Considerations

Google Maps usage is generally free but has quotas:
- Maps JavaScript API: Free tier up to 28,000 loads/day
- Places API: Paid service (~$7 per 1000 requests)
- Geocoding API: Paid service (~$5 per 1000 requests)

For development, this is under free tier limits. Monitor usage in Google Cloud Console.

## Future Enhancements

- [ ] Route optimization display
- [ ] Distance calculation between locations
- [ ] Multiple marker support for building locations
- [ ] Drawing tools for site boundaries
- [ ] Street view integration
- [ ] Nearby amenities search
- [ ] Traffic layer overlay
