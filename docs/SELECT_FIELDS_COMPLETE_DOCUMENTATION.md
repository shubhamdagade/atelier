# ProjectInput Select Fields - Complete Documentation

## 🎯 TL;DR (Too Long; Didn't Read)

**Q: How are select option fields populated?**

**A**: From the database table `project_standards`. When ProjectInput page loads:
1. ✅ Fetches `/api/project-standards` from backend
2. ✅ Backend queries `project_standards` table (active records only)
3. ✅ Returns options grouped by category
4. ✅ React renders `<select>` dropdowns using `.map()` over arrays
5. ✅ User selections auto-save to database

**To add new options**: Insert into `project_standards` table with proper category, restart server.

---

## 📖 Quick Navigation

### For Different Roles

**👨‍💼 Project Manager**: Read this file (overview section)
**👨‍💻 Developer**: Read [SELECT_FIELDS_DEVELOPER_GUIDE.md](SELECT_FIELDS_DEVELOPER_GUIDE.md)
**🗄️ Database Admin**: Read [SELECT_FIELDS_QUICK_GUIDE.md](SELECT_FIELDS_QUICK_GUIDE.md)
**🔍 Technical Deep Dive**: Read [SELECT_FIELDS_GUIDE.md](SELECT_FIELDS_GUIDE.md)

---

## 📊 Overview

### What Are Select Fields?

Dropdown (`<select>`) elements in the ProjectInput form that let users choose from predefined options.

### Current Select Fields (3 Total)

| Field | Used In | Category | Count | Examples |
|-------|---------|----------|-------|----------|
| **Application Type** | Building | application_type | 9 | Residential, Clubhouse, MLCP |
| **Residential Type** | Building | residential_type | 4 | Aspi, Casa, Premium, Villa |
| **Flat Type** | Flat/Unit | flat_type | 5 | 1BHK, 2BHK, 3BHK, 4BHK, Studio |

### Where Options Come From

**Database**: `project_standards` table
**Fetched By**: `/api/project-standards` endpoint
**Used In**: `ProjectInput.jsx` component
**Rendered In**: BuildingSection & FlatRow components

---

## 🏗️ Architecture

### Database Schema

```sql
CREATE TABLE project_standards (
    id SERIAL PRIMARY KEY,
    category VARCHAR(100),        -- Type: application_type, residential_type, flat_type
    value VARCHAR(255),           -- Option text: "Residential", "2BHK", etc.
    description TEXT,             -- Help text
    is_active BOOLEAN,            -- true = visible in dropdowns, false = hidden
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Current Data

```sql
-- Application Types (9)
SELECT * FROM project_standards WHERE category = 'application_type' AND is_active = true;
→ Residential, Clubhouse, MLCP, Commercial, Institute, Industrial, Hospital, Hospitality, Data center

-- Residential Types (4)
SELECT * FROM project_standards WHERE category = 'residential_type' AND is_active = true;
→ Aspi, Casa, Premium, Villa

-- Flat Types (5)
SELECT * FROM project_standards WHERE category = 'flat_type' AND is_active = true;
→ 1BHK, 2BHK, 3BHK, 4BHK, Studio
```

---

## 🔄 How It Works

### Step-by-Step Flow

```
1. ProjectInput component mounts
   ↓
2. useEffect hook runs
   ↓
3. Fetch /api/project-standards
   ↓
4. Backend queries database (3 queries)
   ↓
5. Backend returns JSON:
   {
     "applicationTypes": ["Residential", "Clubhouse", ...],
     "residentialTypes": ["Aspi", "Casa", ...],
     "flatTypes": ["1BHK", "2BHK", ...]
   }
   ↓
6. React state updated: setStandards(data)
   ↓
7. Component re-renders
   ↓
8. JSX maps over arrays:
   {standards.applicationTypes?.map(type => <option>{type}</option>)}
   ↓
9. Dropdowns appear with all options
   ↓
10. User selects option
    ↓
11. onChange fires → onUpdate callback
    ↓
12. Auto-save triggered via autoSaveField()
    ↓
13. Data sent to /api/projects (POST or PATCH)
    ↓
14. Database updated
```

### Component Flow Diagram

```
ProjectInput
  ├─ standards state
  │  └─ { applicationTypes: [], residentialTypes: [], flatTypes: [] }
  │
  ├─ useEffect (fetch standards)
  │  └─ Calls /api/project-standards
  │     └─ setStandards(data)
  │
  ├─ BuildingSection (receives standards)
  │  ├─ Application Type select
  │  │  └─ Maps over standards.applicationTypes
  │  └─ Residential Type select (conditional)
  │     └─ Maps over standards.residentialTypes
  │
  └─ FlatRow (receives standards)
     └─ Flat Type select
        └─ Maps over standards.flatTypes
```

---

## 💾 Database Operations

### View Current Options

```sql
-- All options with descriptions
SELECT category, value, description, is_active 
FROM project_standards 
ORDER BY category, value;

-- Count by category
SELECT category, COUNT(*) as count
FROM project_standards 
WHERE is_active = true
GROUP BY category;
```

### Add New Option

```sql
INSERT INTO project_standards (category, value, description) 
VALUES ('flat_type', 'Penthouse', 'High-rise penthouse apartment');
```

### Edit Option Description

```sql
UPDATE project_standards 
SET description = 'New description'
WHERE category = 'flat_type' AND value = 'Penthouse';
```

### Hide Option (Without Deleting)

```sql
UPDATE project_standards 
SET is_active = false 
WHERE category = 'application_type' AND value = 'Old Type';
```

### Show Hidden Option

```sql
UPDATE project_standards 
SET is_active = true 
WHERE category = 'application_type' AND value = 'Old Type';
```

### Delete Option (Permanent)

```sql
DELETE FROM project_standards 
WHERE category = 'application_type' AND value = 'To Delete';
```

---

## 🔌 API Endpoint

### GET /api/project-standards

**Location**: `server/index.js` line 336

**Purpose**: Fetch all active standards grouped by category

**Request**:
```bash
GET http://localhost:5000/api/project-standards
```

**Response**:
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

**Error Response**:
```json
{
  "error": "Failed to fetch standards"
}
```

**Backend Code**:
```javascript
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

---

## 📝 Frontend Implementation

### React Component Code

**File**: `src/pages/ProjectInput.jsx`

**State Definition**:
```javascript
const [standards, setStandards] = useState({
  applicationTypes: [],
  residentialTypes: [],
  flatTypes: [],
});
```

**Fetch Data**:
```javascript
useEffect(() => {
  const fetchStandards = async () => {
    try {
      const response = await fetch('/api/project-standards');
      if (response.ok) {
        const data = await response.json();
        setStandards(data);
      }
    } catch (err) {
      console.error('Error fetching standards:', err);
    }
  };
  
  fetchStandards();
}, []);
```

**Render Select**:
```jsx
<select value={building.applicationType} onChange={e => onUpdate(building.id, { applicationType: e.target.value })}>
  <option value="">Select type...</option>
  {standards.applicationTypes?.map(type => (
    <option key={type} value={type}>
      {type}
    </option>
  ))}
</select>
```

---

## 🎯 Use Cases

### Adding a New Application Type

**Scenario**: Need to add "Government" as application type

**Steps**:
1. Database:
   ```sql
   INSERT INTO project_standards (category, value, description) 
   VALUES ('application_type', 'Government', 'Government buildings');
   ```
2. Restart dev server
3. Go to ProjectInput → add building → see "Government" in Application Type dropdown

### Adding a New Flat Type

**Scenario**: Need to add "1.5BHK" flat type

**Steps**:
1. Database:
   ```sql
   INSERT INTO project_standards (category, value, description) 
   VALUES ('flat_type', '1.5BHK', 'One and half bedroom apartment');
   ```
2. Restart dev server
3. Go to ProjectInput → add flat → see "1.5BHK" in Flat Type dropdown

### Hiding Old Options

**Scenario**: "Hospitality" is no longer used

**Steps**:
1. Database:
   ```sql
   UPDATE project_standards 
   SET is_active = false 
   WHERE value = 'Hospitality';
   ```
2. Restart dev server
3. Application Type dropdown no longer shows "Hospitality"
4. Existing buildings with "Hospitality" still show it in their details

---

## ❓ Troubleshooting

### Problem: Dropdowns are Empty

**Check 1**: Database has data
```sql
SELECT COUNT(*) FROM project_standards WHERE is_active = true;
-- Should return: 18 (3 + 4 + 5 + 6 for "Other")
```

**Check 2**: API returns data
```bash
curl http://localhost:5000/api/project-standards
-- Should see JSON with arrays
```

**Check 3**: Frontend received data
- DevTools → Components → ProjectInput
- Check `standards` state
- Should have arrays with options

**Solution**: Restart server
```bash
npm run dev
```

### Problem: New Option Not Showing

**Check 1**: Is it marked as active?
```sql
SELECT * FROM project_standards WHERE value = 'My Option' AND is_active = false;
-- If found, update to true:
UPDATE project_standards SET is_active = true WHERE value = 'My Option';
```

**Check 2**: Is it in correct category?
```sql
SELECT * FROM project_standards WHERE value = 'My Option';
-- Verify category matches (application_type, residential_type, or flat_type)
```

**Check 3**: Browser cache
- Clear cache: Ctrl+Shift+Delete
- Restart dev server
- Refresh page

### Problem: Option Disappeared

**Cause**: Might be deactivated

**Solution**:
```sql
SELECT * FROM project_standards WHERE is_active = false;
-- Reactivate:
UPDATE project_standards SET is_active = true;
```

---

## 📋 Reference Tables

### Application Types

| Value | Description | Use Case |
|-------|-------------|----------|
| Residential | Residential buildings | Apartments, flats |
| Clubhouse | Club and community spaces | Common areas |
| MLCP | Multi-Level Car Parking | Parking structures |
| Commercial | Commercial spaces | Retail, offices |
| Institute | Educational institutions | Schools, colleges |
| Industrial | Industrial facilities | Factories, warehouses |
| Hospital | Hospital facilities | Medical centers |
| Hospitality | Hotels and hospitality | Hotels, resorts |
| Data center | Data center facilities | Server facilities |

### Residential Types

| Value | Description | Use Case |
|-------|-------------|----------|
| Aspi | Aspire series | Budget apartments |
| Casa | Casa series | Mid-range apartments |
| Premium | Premium series | High-end apartments |
| Villa | Villa series | Standalone villas |
| Other | Custom type | Special cases |

### Flat Types

| Value | Description | Bedrooms | Use Case |
|-------|-------------|----------|----------|
| Studio | Studio apartment | 0 | Single occupant |
| 1BHK | One Bedroom | 1 | Starter homes |
| 2BHK | Two Bedroom | 2 | Young families |
| 3BHK | Three Bedroom | 3 | Growing families |
| 4BHK | Four Bedroom | 4 | Large families |

---

## 🚀 Future Enhancements

### Could Add
1. **Admin UI** for managing standards
2. **Categorization** of standards (Basic, Premium, Luxury)
3. **Icons** for each option
4. **Search functionality** in long dropdowns
5. **Custom options** user can add themselves
6. **Translations** for multi-language support
7. **Descriptions** shown on hover
8. **Grouping** of options (e.g., Residential → Aspi, Casa, Premium)

---

## 📞 Support & Resources

### Documentation
- [SELECT_FIELDS_GUIDE.md](SELECT_FIELDS_GUIDE.md) - Detailed guide
- [SELECT_FIELDS_QUICK_GUIDE.md](SELECT_FIELDS_QUICK_GUIDE.md) - SQL reference
- [SELECT_FIELDS_DEVELOPER_GUIDE.md](SELECT_FIELDS_DEVELOPER_GUIDE.md) - Implementation details

### Code Files
- **Component**: `src/pages/ProjectInput.jsx`
- **Database**: `schema.sql`
- **Backend**: `server/index.js` (line 336)

### Commands
```bash
# Connect to database
psql -U postgres -d atelier_db

# View standards
SELECT * FROM project_standards;

# Test API
curl http://localhost:5000/api/project-standards

# Restart server
npm run dev
```

---

## Summary

**Select fields are populated by**:
- Fetching from `/api/project-standards` endpoint
- Backend queries `project_standards` database table
- Results organized by category
- React renders options dynamically
- User selections auto-save

**To manage options**:
- Add: `INSERT INTO project_standards`
- Edit: `UPDATE project_standards`
- Hide: `UPDATE is_active = false`
- Show: `UPDATE is_active = true`
- Delete: `DELETE FROM project_standards`

**Key Points**:
- Options stored in database (flexible)
- Easy to add/remove via SQL
- Backend filters active items
- Frontend renders from state arrays
- Auto-save integrated seamlessly
- No code changes needed to add options
