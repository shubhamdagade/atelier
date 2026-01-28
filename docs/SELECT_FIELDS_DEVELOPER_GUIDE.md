# ProjectInput Select Fields - Developer Implementation Guide

## 📌 Where Are The Select Fields?

### File Structure
```
src/pages/ProjectInput.jsx
├── BuildingSection component
│   ├── Application Type select
│   └── Residential Type select (conditional)
└── FlatRow component
    └── Flat Type select
```

---

## 1️⃣ Application Type Select

### Location
`src/pages/ProjectInput.jsx` - BuildingSection component (around line 457)

### How It Works
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

### What It Does
- Renders all active application types from database
- Stores selection in `projectData.buildings[].applicationType`
- Triggers `onUpdate` callback which updates building
- Auto-saves to database via `autoSaveField()`

### Options Available
```
Residential, Clubhouse, MLCP, Commercial, 
Institute, Industrial, Hospital, Hospitality, Data center
```

### Usage Example
```javascript
// Accessing the value
const appType = building.applicationType;
// e.g., "Residential"

// Changing the value
onUpdate(buildingId, { applicationType: 'Commercial' });

// Conditional rendering based on it
const isResidential = building.applicationType === 'Residential';
```

---

## 2️⃣ Residential Type Select

### Location
`src/pages/ProjectInput.jsx` - BuildingSection component (around line 476)

### How It Works
```jsx
{isResidential && (
  <div className="mb-4">
    <label className="block text-sm font-jost font-semibold mb-2">
      Residential Type
    </label>
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

### What It Does
- Only appears when Application Type = 'Residential'
- Renders all active residential types from database
- Stores selection in `projectData.buildings[].residentialType`
- Always includes "Other" option
- Auto-saves to database

### Options Available
```
Aspi, Casa, Premium, Villa, Other
```

### Key Difference
- **Conditional Rendering**: Uses `{isResidential && (...)}`
- **Extra Option**: "Other" is hardcoded

### Usage Example
```javascript
// Check if residential
const isResidential = building.applicationType === 'Residential';

// Access value
const residType = building.residentialType;
// e.g., "Aspi" or "Other"

// Condition for Villa
const isVilla = building.applicationType === 'Villa' || 
                building.residentialType === 'Villa';
```

---

## 3️⃣ Flat Type Select

### Location
`src/pages/ProjectInput.jsx` - FlatRow component (around line 657)

### How It Works
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

### What It Does
- Renders all active flat types from database
- Stores selection in `projectData.buildings[].floors[].flats[].type`
- Triggers `updateFlat` callback which updates flat
- Auto-saves to database

### Options Available
```
1BHK, 2BHK, 3BHK, 4BHK, Studio
```

### Usage Example
```javascript
// Access value
const flatType = flat.type;
// e.g., "2BHK"

// Filter flats of specific type
const bedrooms2 = floor.flats.filter(f => f.type === '2BHK');

// Count flats of each type
const flatTypeCounts = floor.flats.reduce((acc, f) => {
  acc[f.type] = (acc[f.type] || 0) + 1;
  return acc;
}, {});
// Output: { "2BHK": 5, "1BHK": 3, ... }
```

---

## 🔄 Data Flow for Each Select

### Application Type Flow
```
User clicks Application Type select
         ↓
Selects "Residential"
         ↓
onChange triggers
         ↓
onUpdate(buildingId, { applicationType: 'Residential' })
         ↓
updateBuilding function runs
         ↓
projectData.buildings[id].applicationType = 'Residential'
         ↓
setProjectData triggers re-render
         ↓
autoSaveField('applicationType', 'Residential')
         ↓
POST /api/projects with data
         ↓
Database updates
```

---

## 🔌 Integration Points

### In BuildingSection Component
```jsx
// Props passed
<BuildingSection
  building={building}
  standards={standards}
  onUpdate={updateBuilding}
/>

// Inside component
export function BuildingSection({ building, standards, onUpdate }) {
  const isResidential = building.applicationType === 'Residential';
  const isVilla = building.applicationType === 'Villa' || 
                  building.residentialType === 'Villa';
  
  return (
    // ... JSX with selects ...
  );
}
```

### In FlatRow Component
```jsx
// Props passed
<FlatRow
  key={flat.id}
  flat={flat}
  standards={standards}
  updateFlat={updateFlat}
/>

// Inside component
export function FlatRow({ flat, standards, updateFlat }) {
  return (
    // ... JSX with select ...
  );
}
```

---

## ✅ How to Verify It's Working

### Check 1: Console Logging
```jsx
// Add temporary console.log
{standards.applicationTypes?.map(type => {
  console.log('Rendering option:', type);
  return (
    <option key={type} value={type}>{type}</option>
  );
})}
```

### Check 2: React DevTools
1. Open DevTools → Components tab
2. Find ProjectInput component
3. Inspect state → look for `standards` object
4. Should see arrays with options

### Check 3: Browser DevTools Console
```javascript
// Fetch standards manually
fetch('/api/project-standards')
  .then(r => r.json())
  .then(d => console.table(d))
```

### Check 4: Network Tab
1. DevTools → Network tab
2. Go to ProjectInput page
3. Find `/api/project-standards` request
4. Click it → Response tab
5. Should see JSON with all three arrays

---

## 🛠️ Modifying Select Behavior

### Add Placeholder Logic
```jsx
<select 
  value={building.applicationType}
  onChange={e => {
    const value = e.target.value;
    // Reset residential type when application type changes
    if (value !== 'Residential') {
      onUpdate(building.id, { 
        applicationType: value,
        residentialType: '' 
      });
    } else {
      onUpdate(building.id, { applicationType: value });
    }
  }}
>
  {/* ... options ... */}
</select>
```

### Add Validation
```jsx
<select
  value={building.applicationType}
  onChange={e => {
    const value = e.target.value;
    if (!value) {
      console.warn('Application type cannot be empty');
      return;
    }
    onUpdate(building.id, { applicationType: value });
  }}
>
  {/* ... options ... */}
</select>
```

### Add Disabled State
```jsx
<select
  value={building.applicationType}
  onChange={e => onUpdate(building.id, { applicationType: e.target.value })}
  disabled={building.isTemplate}
>
  {/* ... options ... */}
</select>
```

---

## 🚀 Adding a New Select Field

### Step 1: Add to Database
```sql
INSERT INTO project_standards (category, value, description) VALUES
('my_category', 'Option 1', 'Description'),
('my_category', 'Option 2', 'Description');
```

### Step 2: Update Backend API
```javascript
// In server/index.js
app.get('/api/project-standards', async (req, res) => {
  // ... existing code ...
  
  const myCategory = await query(
    'SELECT DISTINCT value FROM project_standards WHERE category = $1 AND is_active = true ORDER BY value',
    ['my_category']
  );
  
  res.json({
    applicationTypes: applicationTypes.rows.map(r => r.value),
    residentialTypes: residentialTypes.rows.map(r => r.value),
    flatTypes: flatTypes.rows.map(r => r.value),
    myCategory: myCategory.rows.map(r => r.value),  // ← Add this
  });
});
```

### Step 3: Update React State
```javascript
const [standards, setStandards] = useState({
  applicationTypes: [],
  residentialTypes: [],
  flatTypes: [],
  myCategory: [],  // ← Add this
});
```

### Step 4: Use in JSX
```jsx
<select value={building.myField} onChange={e => onUpdate(building.id, { myField: e.target.value })}>
  <option value="">Select...</option>
  {standards.myCategory?.map(option => (
    <option key={option} value={option}>{option}</option>
  ))}
</select>
```

---

## 📊 Example: Adding "Parking Type" Select

### Full Implementation

**1. Database**:
```sql
INSERT INTO project_standards (category, value, description) VALUES
('parking_type', 'Open', 'Open air parking'),
('parking_type', 'Covered', 'Covered parking'),
('parking_type', 'Underground', 'Underground parking');
```

**2. Backend** (server/index.js):
```javascript
app.get('/api/project-standards', async (req, res) => {
  try {
    // ... existing queries ...
    
    const parkingTypes = await query(
      'SELECT DISTINCT value FROM project_standards WHERE category = $1 AND is_active = true ORDER BY value',
      ['parking_type']
    );
    
    res.json({
      applicationTypes: applicationTypes.rows.map(r => r.value),
      residentialTypes: residentialTypes.rows.map(r => r.value),
      flatTypes: flatTypes.rows.map(r => r.value),
      parkingTypes: parkingTypes.rows.map(r => r.value),
    });
  } catch (error) {
    console.error('Error fetching standards:', error);
    res.status(500).json({ error: 'Failed to fetch standards' });
  }
});
```

**3. Frontend State** (ProjectInput.jsx):
```javascript
const [standards, setStandards] = useState({
  applicationTypes: [],
  residentialTypes: [],
  flatTypes: [],
  parkingTypes: [],
});
```

**4. JSX** (In BuildingSection component):
```jsx
<div>
  <label className="block text-sm font-jost font-semibold mb-2">Parking Type</label>
  <select
    value={building.parkingType || ''}
    onChange={e => onUpdate(building.id, { parkingType: e.target.value })}
    className="w-full px-3 py-2 border border-lodha-grey rounded focus:outline-none focus:ring-2 focus:ring-lodha-gold"
  >
    <option value="">Select parking type...</option>
    {standards.parkingTypes?.map(type => (
      <option key={type} value={type}>{type}</option>
    ))}
  </select>
</div>
```

---

## 🎯 Key Takeaways

1. **All selects use same pattern**: Get options from state, map to render options
2. **Data flows**: Database → Backend → React State → Rendered Options
3. **Always use optional chaining** (`?.map()`) for safety
4. **Conditional rendering** can control when selects appear
5. **Auto-save** happens automatically via `autoSaveField()`
6. **To add options**: Just INSERT into database, restart server, options appear

---

## 🔗 Related Files

- **Component**: `src/pages/ProjectInput.jsx`
- **Database**: `schema.sql` (project_standards table)
- **Backend**: `server/index.js` (GET /api/project-standards)
- **Docs**: `SELECT_FIELDS_GUIDE.md` (detailed guide)
- **Docs**: `SELECT_FIELDS_QUICK_GUIDE.md` (quick reference)
