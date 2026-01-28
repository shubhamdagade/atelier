# ProjectInput Select Fields - Quick Reference & Management

## 🎯 Quick Answer

Select option fields are populated from the **`project_standards`** database table. When ProjectInput component loads, it fetches all active standards from the `/api/project-standards` endpoint and uses them to render dropdown options.

---

## 📊 Current Select Fields Overview

| Field | Type | Category | Location | Default Options |
|-------|------|----------|----------|-----------------|
| **Application Type** | Required | application_type | Building | Residential, Clubhouse, MLCP, Commercial, etc. |
| **Residential Type** | Conditional | residential_type | Building | Aspi, Casa, Premium, Villa |
| **Flat Type** | Required | flat_type | Flat | 1BHK, 2BHK, 3BHK, 4BHK, Studio |

---

## 🔄 Data Flow (Simple)

```
Database (project_standards) 
    ↓ SQL Query (category-based)
Backend API (/api/project-standards)
    ↓ JSON Response
React State (standards object)
    ↓ .map() over arrays
<select> Options
    ↓ User Selection
Save to projectData
    ↓ Auto-save to DB
```

---

## 💾 Managing Options via Database

### View Current Options

```sql
-- See all standards
SELECT category, value, description, is_active 
FROM project_standards 
ORDER BY category, value;

-- Count by category
SELECT category, COUNT(*) 
FROM project_standards 
WHERE is_active = true 
GROUP BY category;
```

### Add New Options

```sql
-- Add new application type
INSERT INTO project_standards (category, value, description) 
VALUES ('application_type', 'New Type', 'Description');

-- Add new residential series
INSERT INTO project_standards (category, value, description) 
VALUES ('residential_type', 'Luxury', 'Luxury apartments');

-- Add new flat type
INSERT INTO project_standards (category, value, description) 
VALUES ('flat_type', '5BHK', 'Five Bedroom Hall Kitchen');
```

### Deactivate Options (Hide from Dropdowns)

```sql
-- Hide an option without deleting
UPDATE project_standards 
SET is_active = false 
WHERE category = 'application_type' AND value = 'Old Type';

-- Show it again
UPDATE project_standards 
SET is_active = true 
WHERE category = 'application_type' AND value = 'Old Type';
```

### Delete Options

```sql
-- Remove a standard (use with caution)
DELETE FROM project_standards 
WHERE category = 'application_type' AND value = 'Type To Delete';
```

---

## 📋 Complete Option Lists

### Application Types (9 options)
```
Residential         → for residential buildings
Clubhouse           → for club/community spaces
MLCP                → for multi-level car parking
Commercial          → for commercial spaces
Institute           → for schools/colleges
Industrial          → for factories/warehouses
Hospital            → for medical facilities
Hospitality         → for hotels/resorts
Data center         → for server facilities
```

### Residential Types (4 options)
*Only shown when Application Type = 'Residential'*
```
Aspi                → Aspire series
Casa                → Casa series
Premium             → Premium apartments
Villa               → Villa series
Other               → Hardcoded, always available
```

### Flat Types (5 options)
```
1BHK                → One Bedroom Hall Kitchen
2BHK                → Two Bedroom Hall Kitchen
3BHK                → Three Bedroom Hall Kitchen
4BHK                → Four Bedroom Hall Kitchen
Studio              → Studio apartment
```

---

## 🛠️ Adding Options - Step by Step

### Scenario: Add "Penthouse" as new flat type

**Step 1**: Connect to database
```bash
psql -U postgres -d atelier_db
```

**Step 2**: Insert new option
```sql
INSERT INTO project_standards (category, value, description) 
VALUES ('flat_type', 'Penthouse', 'High-rise penthouse apartment');
```

**Step 3**: Verify insertion
```sql
SELECT * FROM project_standards 
WHERE category = 'flat_type' 
ORDER BY value;
```

**Step 4**: Test in app
- Stop dev server: `Ctrl+C`
- Start dev server: `npm run dev`
- Go to ProjectInput page
- Create/edit a building → go to Flats section
- See "Penthouse" in Flat Type dropdown ✓

---

## 🔍 Finding What's in the Database

### All Standards
```sql
SELECT * FROM project_standards;
```

### By Category
```sql
-- All application types
SELECT value FROM project_standards WHERE category = 'application_type';

-- All residential types
SELECT value FROM project_standards WHERE category = 'residential_type';

-- All flat types
SELECT value FROM project_standards WHERE category = 'flat_type';
```

### Active vs Inactive
```sql
-- Only active (shown in dropdowns)
SELECT * FROM project_standards WHERE is_active = true;

-- Inactive (hidden)
SELECT * FROM project_standards WHERE is_active = false;
```

### Recently Added
```sql
SELECT category, value, created_at 
FROM project_standards 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## 🚀 Testing the Dropdowns

### Test Without Database Changes

1. Open browser DevTools (F12)
2. Go to ProjectInput page
3. Open Console tab
4. Run:
   ```javascript
   // Fetch standards manually
   fetch('/api/project-standards')
     .then(r => r.json())
     .then(data => console.log(JSON.stringify(data, null, 2)))
   ```
5. Check console output for all options

### Test in Network Tab

1. Open DevTools → Network tab
2. Go to ProjectInput page
3. Look for `/api/project-standards` request
4. Click it → Preview tab → see response data
5. Should show all three arrays

---

## ⚙️ Backend Configuration

### Endpoint: GET /api/project-standards

**Location**: `server/index.js` line 336

**What it does**:
1. Queries database for application_types (active only)
2. Queries database for residential_types (active only)  
3. Queries database for flat_types (active only)
4. Returns combined JSON

**Response Format**:
```json
{
  "applicationTypes": ["Residential", "Clubhouse", ...],
  "residentialTypes": ["Aspi", "Casa", ...],
  "flatTypes": ["1BHK", "2BHK", ...]
}
```

**Never Caches**: Each request hits database fresh

---

## 🎨 Frontend Implementation

### How React Uses It

```jsx
// 1. State to store standards
const [standards, setStandards] = useState({
  applicationTypes: [],
  residentialTypes: [],
  flatTypes: [],
});

// 2. Fetch on mount
useEffect(() => {
  fetch('/api/project-standards')
    .then(r => r.json())
    .then(data => setStandards(data))
}, []);

// 3. Render select with options
<select>
  <option value="">Select...</option>
  {standards.applicationTypes?.map(type => (
    <option key={type} value={type}>{type}</option>
  ))}
</select>
```

### Optional Chaining Safety

Note the `?.map()` - this prevents errors if standards aren't loaded yet.

---

## 🐛 Common Issues & Fixes

### Dropdown is Empty

**Check 1**: Database has data
```sql
SELECT COUNT(*) FROM project_standards WHERE is_active = true;
```
Should return > 0

**Check 2**: Backend returns data
```bash
curl http://localhost:5000/api/project-standards
```
Should see JSON with arrays

**Check 3**: Frontend receives data
- DevTools → React Components tab
- Find ProjectInput
- Inspect `standards` state
- Should have arrays populated

**Fix**: Restart dev server
```bash
npm run dev
```

### New Option Not Showing

**Issue**: Added to database but not in dropdown

**Cause 1**: Not marked as active
```sql
UPDATE project_standards 
SET is_active = true 
WHERE value = 'My New Option';
```

**Cause 2**: Browser cache
- Clear cache: Ctrl+Shift+Delete
- Restart dev server
- Refresh page

**Cause 3**: Wrong category
```sql
-- Check what you inserted
SELECT * FROM project_standards 
WHERE value = 'My New Option';

-- Verify category matches what code expects
```

### Option Disappears Randomly

**Cause**: Might be deactivated
```sql
-- Check if deactivated
SELECT * FROM project_standards 
WHERE is_active = false;

-- Reactivate
UPDATE project_standards 
SET is_active = true 
WHERE is_active = false;
```

---

## 📝 SQL Cheat Sheet

```sql
-- See all options
SELECT * FROM project_standards;

-- Add option
INSERT INTO project_standards (category, value, description) 
VALUES ('application_type', 'My Type', 'Description');

-- Edit option
UPDATE project_standards 
SET description = 'New description' 
WHERE value = 'My Type';

-- Hide option
UPDATE project_standards 
SET is_active = false 
WHERE value = 'My Type';

-- Show option
UPDATE project_standards 
SET is_active = true 
WHERE value = 'My Type';

-- Delete option
DELETE FROM project_standards 
WHERE value = 'My Type';

-- Count by category
SELECT category, COUNT(*) 
FROM project_standards 
GROUP BY category;

-- Show only application types
SELECT value FROM project_standards 
WHERE category = 'application_type' AND is_active = true;

-- Show only residential types
SELECT value FROM project_standards 
WHERE category = 'residential_type' AND is_active = true;

-- Show only flat types
SELECT value FROM project_standards 
WHERE category = 'flat_type' AND is_active = true;
```

---

## 🎯 Next Steps

### To Add More Options
1. Connect to PostgreSQL
2. Use INSERT statements above
3. Restart dev server
4. New options appear in dropdowns

### To Hide Old Options
1. Use UPDATE to set `is_active = false`
2. Options won't appear in dropdowns
3. Existing data still saved (not deleted)

### To Create Admin UI (Future)
Could build a page for super admin to:
- View all standards
- Add new standards
- Edit descriptions
- Toggle active/inactive
- Delete standards

---

## Summary

**SelectFields are populated from**:
- Database table: `project_standards`
- Grouped by: `category` column
- Backend endpoint: `/api/project-standards`
- Frontend state: `standards` object
- Rendered via: `.map()` in JSX

**To manage options**:
- Add: `INSERT INTO project_standards`
- Edit: `UPDATE project_standards`
- Hide: `UPDATE is_active = false`
- Delete: `DELETE FROM project_standards`
- View: `SELECT * FROM project_standards`

**Current options** available in code are defined in `schema.sql` INSERT statements and can be modified via SQL.
