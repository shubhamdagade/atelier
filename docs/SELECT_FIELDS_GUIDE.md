# ProjectInput Select Fields - Population Guide

## Overview

The ProjectInput page has multiple `<select>` dropdown fields that are dynamically populated from the database. Here's how they work:

---

## How Select Fields Are Populated

### Architecture Diagram

```
┌──────────────────────┐
│   ProjectInput.jsx   │
│  Component Mounts    │
└──────────┬───────────┘
           │
           ├→ useEffect runs
           │
           ↓
┌──────────────────────────────┐
│  Fetch /api/project-standards│
└──────────┬───────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  Backend Returns:                    │
│  {                                   │
│    applicationTypes: [...]           │
│    residentialTypes: [...]           │
│    flatTypes: [...]                  │
│  }                                   │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────┐
│  setStandards(data)          │
│  Updates React State         │
└──────────┬───────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  .map() over standards arrays        │
│  Create <option> elements            │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────┐
│  Render Select Dropdowns     │
│  with All Options            │
└──────────────────────────────┘
```

---

## Current Select Fields

### 1. Application Type (Building Level)

**Location**: BuildingSection component
**Database Table**: `project_standards` (category = 'application_type')

**Current Options**:
- Residential
- Clubhouse
- MLCP (Multi-Level Car Parking)
- Commercial
- Institute
- Industrial
- Hospital
- Hospitality
- Data center

**Code**:
```jsx
<select
  value={building.applicationType}
  onChange={e => onUpdate(building.id, { applicationType: e.target.value })}
  className="w-full px-3 py-2 border border-lodha-grey rounded focus:outline-none focus:ring-2 focus:ring-lodha-gold"
>
  <option value="">Select type...</option>
  {standards.applicationTypes?.map(type => (
    <option key={type} value={type}>
      {type}
    </option>
  ))}
</select>
```

---

### 2. Residential Type (Building Level)

**Location**: BuildingSection component (conditional: appears only if Application Type = 'Residential')
**Database Table**: `project_standards` (category = 'residential_type')

**Current Options**:
- Aspi (Aspire series)
- Casa (Casa series)
- Premium (Premium series)
- Villa (Villa series)
- Other (hardcoded)

**Code**:
```jsx
{isResidential && (
  <div className="mb-4">
    <label className="block text-sm font-jost font-semibold mb-2">Residential Type</label>
    <select
      value={building.residentialType}
      onChange={e => onUpdate(building.id, { residentialType: e.target.value })}
      className="w-full px-3 py-2 border border-lodha-grey rounded focus:outline-none focus:ring-2 focus:ring-lodha-gold"
    >
      <option value="">Select type...</option>
      {standards.residentialTypes?.map(type => (
        <option key={type} value={type}>
          {type}
        </option>
      ))}
      <option value="Other">Other</option>
    </select>
  </div>
)}
```

---

### 3. Flat Type (Flat Row Level)

**Location**: FlatRow component
**Database Table**: `project_standards` (category = 'flat_type')

**Current Options**:
- 1BHK
- 2BHK
- 3BHK
- 4BHK
- Studio

**Code**:
```jsx
<select
  value={flat.type}
  onChange={e => updateFlat(flat.id, { type: e.target.value })}
  className="px-3 py-2 border border-lodha-grey rounded focus:outline-none focus:ring-2 focus:ring-lodha-gold"
>
  <option value="">Select type...</option>
  {standards.flatTypes?.map(type => (
    <option key={type} value={type}>
      {type}
    </option>
  ))}
</select>
```

---

## Data Flow: From Database to UI

### Step 1: Initial Fetch (Component Mount)

```jsx
// ProjectInput.jsx - useEffect hook
useEffect(() => {
  const fetchStandards = async () => {
    try {
      const response = await fetch('/api/project-standards');
      if (response.ok) {
        const data = await response.json();
        setStandards(data);  // ← Updates state with all options
      }
    } catch (err) {
      console.error('Error fetching standards:', err);
    }
  };
  
  fetchStandards();
  
  if (isEditing) {
    fetchProjectData();
  } else {
    setLoading(false);
  }
}, [projectId, isEditing]);
```

### Step 2: Backend Returns Data

```javascript
// server/index.js - GET /api/project-standards
app.get('/api/project-standards', async (req, res) => {
  try {
    const applicationTypes = await query(
      'SELECT DISTINCT value FROM project_standards WHERE category = $1 AND is_active = true ORDER BY value',
      ['application_type']
    );
    const residentialTypes = await query(
      'SELECT DISTINCT value FROM project_standards WHERE category = $1 AND is_active = true ORDER BY value',
      ['residential_type']
    );
    const flatTypes = await query(
      'SELECT DISTINCT value FROM project_standards WHERE category = $1 AND is_active = true ORDER BY value',
      ['flat_type']
    );

    res.json({
      applicationTypes: applicationTypes.rows.map(r => r.value),
      residentialTypes: residentialTypes.rows.map(r => r.value),
      flatTypes: flatTypes.rows.map(r => r.value),
    });
  } catch (error) {
    console.error('Error fetching standards:', error);
    res.status(500).json({ error: 'Failed to fetch standards' });
  }
});
```

### Step 3: Render Options

```jsx
// React renders <option> elements from arrays
{standards.applicationTypes?.map(type => (
  <option key={type} value={type}>
    {type}
  </option>
))}
```

---

## Database Schema

```sql
CREATE TABLE project_standards (
    id SERIAL PRIMARY KEY,
    category VARCHAR(100) NOT NULL,        -- e.g., 'application_type'
    value VARCHAR(255) NOT NULL,           -- e.g., 'Residential'
    description TEXT,                      -- e.g., 'Residential buildings'
    is_active BOOLEAN DEFAULT TRUE,        -- Only active items shown
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(category, value)
);

-- Current Data
SELECT * FROM project_standards;

category              | value         | description
──────────────────────┼───────────────┼────────────────────────
application_type      | Residential   | Residential buildings
application_type      | Clubhouse     | Club and community spaces
application_type      | MLCP          | Multi-Level Car Parking
application_type      | Commercial    | Commercial spaces
application_type      | Institute     | Educational institutions
application_type      | Industrial    | Industrial facilities
application_type      | Hospital      | Hospital facilities
application_type      | Hospitality   | Hotels and hospitality
application_type      | Data center   | Data center facilities
residential_type      | Aspi          | Aspire series
residential_type      | Casa          | Casa series
residential_type      | Premium       | Premium series
residential_type      | Villa         | Villa series
flat_type             | 1BHK          | One Bedroom Hall Kitchen
flat_type             | 2BHK          | Two Bedroom Hall Kitchen
flat_type             | 3BHK          | Three Bedroom Hall Kitchen
flat_type             | 4BHK          | Four Bedroom Hall Kitchen
flat_type             | Studio        | Studio apartment
```

---

## How to Add New Options

### Option 1: Direct Database Insert

```sql
-- Add new application type
INSERT INTO project_standards (category, value, description) VALUES
('application_type', 'My New Type', 'Description here');

-- Add new residential type
INSERT INTO project_standards (category, value, description) VALUES
('residential_type', 'My Series', 'Description here');

-- Add new flat type
INSERT INTO project_standards (category, value, description) VALUES
('flat_type', '5BHK', 'Five Bedroom Hall Kitchen');
```

### Option 2: Create Super Admin Management Page (Future)

Could create UI for managing these options:
- List all standards
- Add new standards
- Edit existing standards
- Mark as active/inactive
- Delete standards

---

## Conditional Rendering

### Application Type Determines Visibility

The form shows different fields based on Application Type selection:

```jsx
const isResidential = building.applicationType === 'Residential';
const isVilla = building.applicationType === 'Villa' || 
                building.residentialType === 'Villa';

{isResidential && (
  // Show Residential Type select
)}

{isVilla && (
  // Show Villa Type input and Villa Count input
)}
```

---

## State Management

### Standards State Structure

```javascript
const [standards, setStandards] = useState({
  applicationTypes: [],    // Array of strings
  residentialTypes: [],    // Array of strings
  flatTypes: [],          // Array of strings
});
```

### Example After Fetch

```javascript
{
  applicationTypes: [
    'Residential',
    'Clubhouse',
    'MLCP',
    'Commercial',
    'Institute',
    'Industrial',
    'Hospital',
    'Hospitality',
    'Data center'
  ],
  residentialTypes: [
    'Aspi',
    'Casa',
    'Premium',
    'Villa'
  ],
  flatTypes: [
    '1BHK',
    '2BHK',
    '3BHK',
    '4BHK',
    'Studio'
  ]
}
```

---

## Troubleshooting

### Selects are Empty

**Cause**: Standards not fetched from backend
**Solution**:
1. Check network tab for `/api/project-standards` request
2. Verify backend is running
3. Check browser console for errors
4. Verify database has standards data

### Options Not Showing

**Cause**: Database records marked as inactive
**Solution**:
```sql
-- Check if standards are active
SELECT * FROM project_standards WHERE is_active = false;

-- Activate them
UPDATE project_standards SET is_active = true WHERE is_active = false;
```

### New Option Not Appearing

**Cause**: 
- Not inserted into database
- Inserted with different category name
- Browser cached old data

**Solution**:
1. Insert into database correctly
2. Stop and restart dev server
3. Clear browser cache (Ctrl+Shift+Delete)
4. Refresh page

---

## Verification Steps

### 1. Check Database
```bash
# Connect to database
psql -U your_user -d atelier_db -h localhost

# Query standards
SELECT category, COUNT(*) as count FROM project_standards GROUP BY category;

# Should output:
# category         | count
# ─────────────────┼──────
# application_type | 9
# residential_type | 4
# flat_type        | 5
```

### 2. Check API Response
```bash
curl http://localhost:5000/api/project-standards
```

**Should return**:
```json
{
  "applicationTypes": [
    "Residential",
    "Clubhouse",
    "MLCP",
    "Commercial",
    "Institute",
    "Industrial",
    "Hospital",
    "Hospitality",
    "Data center"
  ],
  "residentialTypes": [
    "Aspi",
    "Casa",
    "Premium",
    "Villa"
  ],
  "flatTypes": [
    "1BHK",
    "2BHK",
    "3BHK",
    "4BHK",
    "Studio"
  ]
}
```

### 3. Check React State
In browser DevTools → React Components tab:
1. Find ProjectInput component
2. Look at `standards` state
3. Should have all three arrays populated

---

## Performance Notes

- ✅ Fetched once on component mount
- ✅ Cached in component state
- ✅ No duplicate API calls
- ✅ Renders efficiently with `.map()`

---

## Adding New Categories

To add a new category of options (e.g., 'parking_type'):

### 1. Add to Database Schema
```sql
INSERT INTO project_standards (category, value, description) VALUES
('parking_type', 'Covered', 'Covered parking'),
('parking_type', 'Open', 'Open parking'),
('parking_type', 'Underground', 'Underground parking');
```

### 2. Update Backend API
```javascript
app.get('/api/project-standards', async (req, res) => {
  // ... existing code ...
  
  const parkingTypes = await query(
    'SELECT DISTINCT value FROM project_standards WHERE category = $1 AND is_active = true ORDER BY value',
    ['parking_type']
  );
  
  res.json({
    applicationTypes: applicationTypes.rows.map(r => r.value),
    residentialTypes: residentialTypes.rows.map(r => r.value),
    flatTypes: flatTypes.rows.map(r => r.value),
    parkingTypes: parkingTypes.rows.map(r => r.value),  // ← Add this
  });
});
```

### 3. Update React State
```javascript
const [standards, setStandards] = useState({
  applicationTypes: [],
  residentialTypes: [],
  flatTypes: [],
  parkingTypes: [],  // ← Add this
});
```

### 4. Use in Select
```jsx
<select>
  <option value="">Select parking type...</option>
  {standards.parkingTypes?.map(type => (
    <option key={type} value={type}>
      {type}
    </option>
  ))}
</select>
```

---

## Summary

**How it works**:
1. Component mounts → useEffect triggers
2. Fetch `/api/project-standards` from backend
3. Backend queries database for active standards
4. Backend returns arrays by category
5. React state updated with standards
6. React renders `<select>` with `.map()` over arrays
7. User can select options
8. Selection saved to project data

**Key Points**:
- All options stored in database (project_standards table)
- Grouped by category (application_type, residential_type, flat_type)
- Backend filters active records
- Frontend renders from state arrays
- Easy to add/remove options via database

**To Add Options**: Insert into project_standards table with appropriate category.
