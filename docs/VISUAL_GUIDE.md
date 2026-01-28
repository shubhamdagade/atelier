# Google Maps Integration - Visual & Interaction Guide

## User Interface Overview

### ProjectInput Page - Location Section

```
┌─────────────────────────────────────────────────────────────┐
│                     PROJECT DETAILS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Project Name: [________________]                           │
│                                                              │
│  Location (Address): [_________________________________]    │
│                                                              │
│  Latitude: [___________]  Longitude: [___________]          │
│                                                              │
│  [🗺️ Show Google Map]          ← Click to toggle map        │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Search for location or address... 🔍                │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │                                                     │   │
│  │                  [GOOGLE MAP]                      │   │
│  │         Click to place marker                       │   │
│  │         Drag marker to adjust                       │   │
│  │                                                     │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ 💡 Tips:                                            │   │
│  │ • Search for address in search box                 │   │
│  │ • Click on map to place marker                     │   │
│  │ • Drag marker to adjust location                   │   │
│  │ • Coordinates auto-populate from map              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## User Interaction Flows

### Flow 1: Search for Location

```
User Types in Search Box
         ↓
"Times Square" or "Mumbai"
         ↓
Real-time Autocomplete Suggestions
         ↓
User Selects from Suggestions
         ↓
Map Centers on Location
Marker Placed at Location
Address Populated in Search Box
         ↓
Map Updates with Zoom to Location
Coordinates Auto-Populate
         ↓
[Location Search Box]
19.3809
73.9273
         ↓
Auto-Save to Database ✓
```

### Flow 2: Click to Place Marker

```
User Clicks on Map
         ↓
Google Maps Records Click Coordinates
         ↓
Marker Moves to Click Location
         ↓
Reverse Geocoding API Call
         ↓
Google Returns Formatted Address
         ↓
Update Display:
- Search Box: "Address from API"
- Latitude: 19.0760
- Longitude: 72.8777
         ↓
Auto-Save to Database ✓
```

### Flow 3: Drag Marker to Adjust

```
User Drags Marker
         ↓
Marker Follows Mouse Movement (Visual Feedback)
         ↓
User Releases Mouse (Drag End)
         ↓
Coordinates Extracted from New Position
         ↓
Reverse Geocoding API Call
         ↓
Address Updated from API
         ↓
Update Display:
- Latitude: (new value)
- Longitude: (new value)
- Address: (reverse geocoded)
         ↓
Auto-Save to Database ✓
```

---

## Visual State Diagram

```
          ┌──────────────────┐
          │  Initial State   │
          │  Map Hidden      │
          └────────┬─────────┘
                   │
                   │ Click "Show Google Map"
                   ↓
          ┌──────────────────────────────┐
          │  Map Loading State           │
          │  Display: "Loading..."       │
          │  Timeout: 3-5 seconds        │
          └────────┬─────────────────────┘
                   │
                   │ Google Maps API Loads
                   ↓
          ┌──────────────────────────────┐
          │  Map Loaded & Ready          │
          │  - Search Box Active         │
          │  - Map Zoomable/Pannable     │
          │  - Marker at Default (Mumbai)│
          │  - User Can Interact         │
          └───────┬──────────┬───────────┘
                  │          │
          ┌───────┴─┐    ┌──┴─────────┐
          │ Search  │    │ Click/Drag │
          │ Flow    │    │ Flow       │
          └────┬────┘    └──┬─────────┘
               │            │
               ↓            ↓
          ┌──────────────────────────────┐
          │  Auto-Save Triggered         │
          │  - location field            │
          │  - latitude field            │
          │  - longitude field           │
          └────────┬─────────────────────┘
                   │
                   ↓
          ┌──────────────────────────────┐
          │  Database Updated            │
          │  All Fields Persisted        │
          └──────────────────────────────┘
```

---

## Search Autocomplete Suggestions

### User Starts Typing

```
┌─────────────────────────────────────────┐
│ Search for location or address... 🔍     │
├─────────────────────────────────────────┤
│                                          │
│ User Types: "Times S"                    │
│                                          │
│ Suggestions:                             │
│ ✓ Times Square, New York, USA           │
│ ✓ Times Square Hotel, NYC                │
│ ✓ Times Square Station, NYC              │
│                                          │
└─────────────────────────────────────────┘
```

### After Selection

```
┌─────────────────────────────────────────┐
│ Times Square, New York, USA              │
├─────────────────────────────────────────┤
│                                          │
│ [GOOGLE MAP - Centered on Times Sq]     │
│     Marker at Times Square              │
│     Zoom Level: 15                      │
│                                          │
│ Coordinates:                             │
│ Latitude: 40.758896                      │
│ Longitude: -73.985130                    │
│                                          │
└─────────────────────────────────────────┘
```

---

## Map Controls & Features

### Available Controls

```
┌─────────────────────────────┐
│ [+] [-] Zoom Controls       │  Top Right
└─────────────────────────────┘

┌─────────────────────────────┐
│ [🏢] Street View            │  Top Right
└─────────────────────────────┘

┌─────────────────────────────┐
│ [⛶] Fullscreen              │  Top Right
└─────────────────────────────┘

Map Type: Default (Terrain, Satellite options in menu)
```

### User Actions

| Action | Effect | Feedback |
|--------|--------|----------|
| **Scroll Wheel** | Zoom in/out | Smooth zoom animation |
| **Click & Drag** | Pan map | Map follows cursor |
| **Click Location** | Place marker | Marker appears, coords update |
| **Drag Marker** | Move marker | Marker follows cursor, updates on release |
| **Type in Search** | Autocomplete | Suggestions appear in real-time |
| **Select Suggestion** | Center & Mark | Map centers, marker placed |

---

## Data Flow Diagram

```
┌──────────────┐
│  User Input  │
│ (Search/Click)
└──────┬───────┘
       │
       ↓
┌─────────────────────────────┐
│ GoogleMapComponent          │
│ - Handles User Interaction  │
│ - Manages Map State         │
│ - Calls APIs                │
└──────┬──────────────────────┘
       │
       ├─→ Google Maps API      → Marker Updates
       ├─→ Places API           → Autocomplete
       └─→ Geocoding API        → Address Lookup
       │
       ↓
┌─────────────────────────────┐
│ onLocationSelect Callback   │
│ Receives:                   │
│ - address (string)          │
│ - lat (number, 8 decimals)  │
│ - lng (number, 8 decimals)  │
└──────┬──────────────────────┘
       │
       ↓
┌─────────────────────────────┐
│ ProjectInput State Update   │
│ - location: address         │
│ - latitude: lat             │
│ - longitude: lng            │
└──────┬──────────────────────┘
       │
       ↓
┌─────────────────────────────┐
│ autoSaveField() Function    │
│ (3 calls for 3 fields)      │
└──────┬──────────────────────┘
       │
       ↓
┌─────────────────────────────┐
│ Fetch API to Backend        │
│ POST /api/projects          │
│ or PATCH /api/projects/:id  │
└──────┬──────────────────────┘
       │
       ↓
┌─────────────────────────────┐
│ Database Update             │
│ Update projects table       │
│ with new coordinates        │
└─────────────────────────────┘
```

---

## Error States & Recovery

### Map Loading Error

```
┌──────────────────────────────────────┐
│ Show Google Map Button Clicked       │
├──────────────────────────────────────┤
│                                      │
│ ⚠️ Error Loading Google Maps         │
│                                      │
│ You can still manually enter:        │
│ - Location (Address)                 │
│ - Latitude                           │
│ - Longitude                          │
│                                      │
│ [Retry] [Manual Entry]               │
│                                      │
└──────────────────────────────────────┘
```

**Recovery Steps**:
1. Check API key in `.env`
2. Verify domain in API restrictions
3. Restart development server
4. Try again

### Search Not Finding Address

```
User types: "Unknown Place XYZ"
     ↓
No suggestions available
     ↓
User can manually continue typing
or clear and search for different location
     ↓
Or manually enter coordinates:
- Latitude: [___]
- Longitude: [___]
```

---

## Mobile/Responsive Design

### Mobile Layout

```
┌─────────────────────┐
│  PROJECT DETAILS    │
├─────────────────────┤
│ Project Name:       │
│ [________________]  │
│                     │
│ Location:           │
│ [________________]  │
│                     │
│ Lat: [___] Lng:[___]│
│                     │
│ [🗺️ Show Map]        │
│                     │
│ ┌─────────────────┐ │
│ │ Search: [_____] │ │ ← Full width on mobile
│ ├─────────────────┤ │
│ │   [MAP]         │ │ ← Smaller height
│ │   (h-80)        │ │    on mobile
│ │                 │ │
│ ├─────────────────┤ │
│ │ 💡 Tips...      │ │
│ └─────────────────┘ │
│                     │
└─────────────────────┘
```

### Tablet Layout

```
┌──────────────────────────────────┐
│  PROJECT DETAILS                  │
├──────────────────────────────────┤
│ Project Name: [____________]      │
│ Location: [________________]      │
│ Latitude: [___]  Longitude: [___] │
│ [🗺️ Show Map]                     │
│ ┌────────────────────────────────┐│
│ │ Search: [_________________]  🔍 ││
│ ├────────────────────────────────┤│
│ │                                ││
│ │         [MAP - h-96]           ││
│ │                                ││
│ ├────────────────────────────────┤│
│ │ 💡 Tips:                       ││
│ │ • Search for address...        ││
│ │ • Click to place marker        ││
│ └────────────────────────────────┘│
└──────────────────────────────────┘
```

### Desktop Layout

```
┌─────────────────────────────────────────────────────────────┐
│  PROJECT DETAILS                                             │
├─────────────────────────────────────────────────────────────┤
│ Project Name: [____________________]                        │
│ Location: [____________________________]                    │
│ Latitude: [__________]  Longitude: [__________]             │
│ [🗺️ Show Google Map]                                         │
│ ┌────────────────────────────────────────────────────────────┐
│ │ Search for location or address... 🔍                       │
│ ├────────────────────────────────────────────────────────────┤
│ │                                                            │
│ │              [GOOGLE MAP - Full Size]                     │
│ │              h-96 (24rem/384px)                           │
│ │                                                            │
│ │         Click to place • Drag to adjust                   │
│ │                                                            │
│ ├────────────────────────────────────────────────────────────┤
│ │ 💡 Tips:                                                   │
│ │ • Search for address in the search box                   │
│ │ • Click on map to place marker                           │
│ │ • Drag marker to adjust location                         │
│ │ • Coordinates auto-populate from map                     │
│ └────────────────────────────────────────────────────────────┘
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Color & Styling Reference

### Map Component Styling

```
┌─────────────────────────────────────┐
│ Google Search Box                   │
│ • Border: border-lodha-grey         │  Grey border
│ • Focus: ring-lodha-gold            │  Gold ring
│ • Background: white                 │
│ • Text: dark                        │
│ • Icon: Search icon (grey)          │  From Lucide
│                                      │
├─────────────────────────────────────┤
│ Map Container                       │
│ • Background: Default map           │
│ • Border: border-lodha-grey         │  Grey border
│ • Rounded: rounded-lg               │
│ • Shadow: shadow-md                 │
│ • Height: h-96 (384px)              │
│                                      │
├─────────────────────────────────────┤
│ Tips Section                        │
│ • Background: bg-blue-50            │  Light blue
│ • Border: border-blue-200           │
│ • Text: text-blue-800               │
│ • Icon: MapPin (blue)               │
│ • Border: rounded-lg                │
│                                      │
└─────────────────────────────────────┘

Show/Hide Button:
┌─────────────────────────────────┐
│ [🗺️ Show Google Map]            │
│ • Background: bg-lodha-gold/10  │  Light gold
│ • Text Color: text-lodha-gold   │  Gold
│ • Hover: bg-lodha-gold/20       │  Slightly darker
│ • Border: rounded-lg             │
│ • Icon: MapPin                   │
│ • Padding: px-4 py-2             │
└─────────────────────────────────┘
```

---

## Performance Expectations

| Action | Response Time | User Feedback |
|--------|---------------|---------------|
| **Initial Map Load** | 2-3 sec | "Loading..." message |
| **Search Typing** | <100ms | Real-time suggestions |
| **Suggestion Click** | <500ms | Map centers, marker placed |
| **Map Click** | <1 sec | Marker moves, address appears |
| **Marker Drag** | <100ms | Smooth drag animation |
| **Auto-Save** | <500ms | Silent (no UI change) |

---

## Success Indicators

Users will know it's working when they see:

✅ **Map Appears** - After clicking "Show Google Map"
✅ **Search Works** - Typing shows autocomplete suggestions
✅ **Suggestion Selection** - Map centers and marker appears
✅ **Click Placement** - Clicking map places marker
✅ **Drag Feedback** - Dragging marker follows cursor
✅ **Coordinates Update** - Lat/Lng fields change
✅ **Address Lookup** - Address field auto-populates
✅ **Persistence** - Data remains after page refresh
✅ **No Errors** - Console shows no error messages
✅ **Smooth UX** - All interactions feel responsive

---

## Summary

The Google Maps integration provides users with:
- 🗺️ Interactive map for location selection
- 🔍 Address search with autocomplete
- 📍 Click and drag to place/adjust markers
- 📊 Auto-populating coordinates
- 💾 Automatic database persistence
- 📱 Mobile-responsive interface
- ⚡ Fast, smooth interactions
- ❌ Graceful error handling

All wrapped in an intuitive, user-friendly interface that matches the Lodha brand design! 🎉
