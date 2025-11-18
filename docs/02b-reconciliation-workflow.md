# OpenRefine Reconciliation Workflow Guide

## Step-by-Step: Reconciling Museum Data to Wikibase

This guide walks through the actual reconciliation process using the sample dataset.

### Prerequisites
- OpenRefine running at http://localhost:3333
- MediaWiki/Wikibase running at http://localhost:8181
- Sample data: `data/museum-artworks.csv`

---

## Part 1: Import Data into OpenRefine

### 1. Create New Project
1. Open http://localhost:3333
2. Click **"Create Project"** tab
3. Select **"This Computer"**
4. Click **"Choose Files"** and select `museum-artworks.csv`
5. Click **"Next »"**

### 2. Configure Import Settings
- **Character encoding:** UTF-8
- **Parse data as:** CSV / TSV / separator-based files
- **Columns are separated by:** comma
- **Parse cell text into numbers, dates, ...:** Checked
- **Store blank rows:** Unchecked
- **Store blank cells as nulls:** Checked

Click **"Create Project »"**

**Result:** You should see 20 rows with columns: id, title, artist, date, location, medium, dimensions

---

## Part 2: Configure Wikibase Connection

### 1. Add Wikibase Manifest
1. Click **"Extensions"** in top menu
2. Select **"Wikibase"** → **"Manage Wikibase instances"**
3. Click **"Add Wikibase"**
4. Choose **"Add Wikibase manifest"**

### 2. Load Manifest
**Option A - From File:**
- Paste the full path: `/home/pz/projects/TIB_RSE_v2/nfdi4culture-stack/configs/openrefine/nfdi4culture-wikibase-manifest.json`

**Option B - Paste JSON:**
```json
{
  "version": "2.0",
  "name": "NFDI4Culture Wikibase",
  "mediawiki": {
    "api": "http://mediawiki-mediawiki-web-1:8080/w/api.php"
  },
  "wikibase": {
    "site_iri": "http://localhost:8181/entity/",
    "maxlag": 5,
    "tag": "OpenRefine"
  }
}
```

3. Click **"Add"** or **"OK"**

**Verification:** "NFDI4Culture Wikibase" should appear in the list of available Wikibase instances.

---

## Part 3: Reconcile Artist Names

### 1. Start Reconciliation
1. Click on the **"artist"** column dropdown (▼)
2. Select **"Reconcile"** → **"Start reconciling..."**
3. Choose **"NFDI4Culture Wikibase"** as the service
4. Select reconciliation type: **"Item"** (or leave as "Reconcile against no particular type")

### 2. Configure Reconciliation Settings
- **Auto-match candidates with high confidence:** Checked (recommended)
- **Maximum number of results:** 10

Click **"Start Reconciling"**

### 3. Review Results
OpenRefine will show:
- **Green checkmark (✓):** Auto-matched to Q1 (Vincent van Gogh)
- **Yellow icon:** Multiple candidates
- **Red X:** No match found

### 4. Manual Verification
For any non-auto-matched cells:
1. Click on the cell
2. Review suggested matches
3. Click **"Match this cell"** for the correct entity (Q1)
4. Or use **"Match all identical cells"** to apply to all similar values

**Expected Result:** All 20 artist names should reconcile to **Q1 (Vincent van Gogh)**

---

## Part 4: Add Reconciliation Facets

### 1. Create Judgment Facet
1. Click **"artist"** column dropdown
2. Select **"Facet"** → **"Reconciliation facets"** → **"Judgment facets"**

You'll see:
- **Matched:** Number of cells successfully reconciled
- **New:** Cells marked for new entity creation
- **None:** Unreconciled cells

### 2. Filter by Judgment
- Click on **"matched"** to see only reconciled rows
- Click on **"none"** to see unreconciled rows that need attention

---

## Part 5: Reconcile Locations (Optional)

Since we only have Q3 (Museum of Modern Art) in our Wikibase, we can:

### Option A: Reconcile "Museum of Modern Art" to Q3
1. Click **"location"** column dropdown
2. **"Reconcile"** → **"Start reconciling..."**
3. Select **"NFDI4Culture Wikibase"**
4. Manually match "Museum of Modern Art" and "MoMA" to Q3

### Option B: Create New Items for Other Museums
1. After reconciliation, cells marked as **"New"** can be exported
2. Use Wikibase schema to create new items for each museum

---

## Part 6: Create Wikibase Upload Schema

### 1. Open Schema Editor
1. Click **"Extensions"** → **"Wikibase"** → **"Edit Wikibase schema"**
2. Select **"NFDI4Culture Wikibase"** as target

### 2. Define Schema Structure

**For Item (Artwork):**
```
Item: Create new item for each row
├── Label: cells["title"].value
├── Description: "painting by " + cells["artist"].recon.match.name + " (" + cells["date"].value + ")"
└── Statements:
    ├── P1 (creator) → cells["artist"].recon.match.id
    └── [Add more properties as needed]
```

**Schema JSON Example:**
```json
{
  "itemDocuments": [
    {
      "subject": {
        "type": "new-item"
      },
      "nameDescs": [
        {
          "type": "label",
          "value": {
            "type": "cell",
            "columnName": "title"
          }
        },
        {
          "type": "description", 
          "value": {
            "type": "constant",
            "value": "painting in museum collection"
          }
        }
      ],
      "statementGroups": [
        {
          "property": {
            "type": "wikibase-item",
            "id": "P1"
          },
          "statements": [
            {
              "value": {
                "type": "wikibase-item",
                "columnName": "artist"
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### 3. Preview Schema
Click **"Preview"** to see what will be uploaded:
- New items to be created
- Statements to be added
- Labels and descriptions

---

## Part 7: Upload to Wikibase

### 1. Authenticate
1. In schema editor, click **"Upload to Wikibase"**
2. You'll be redirected to MediaWiki login
3. Login with Admin credentials from `.env`
4. Authorize OpenRefine to edit on your behalf

### 2. Configure Upload
- **Edit summary:** "Imported museum artworks from OpenRefine"
- **Maximum edits per batch:** 50
- **Maximum lag:** 5 seconds

### 3. Start Upload
Click **"Upload"** and monitor progress:
- Shows number of edits made
- Displays any errors
- Provides links to created/edited items

### 4. Verify in Wikibase
Visit http://localhost:8181 and check:
- New items created (Q4, Q5, Q6... for each artwork)
- Statements linking to Q1 (Vincent van Gogh)
- Edit history shows "OpenRefine" tag

---

## Part 8: Export Results

### Export Reconciled Data
1. Click **"Export"** (top right)
2. Choose format:
   - **CSV** - For further processing
   - **RDF** - For semantic web applications
   - **Wikibase QuickStatements** - For bulk uploads

### Export Schema
1. **"Extensions"** → **"Wikibase"** → **"Export schema"**
2. Save JSON file for reuse with similar datasets

---

## Troubleshooting

### Reconciliation Service Not Found
**Problem:** "NFDI4Culture Wikibase" doesn't appear in reconciliation options

**Solution:**
1. Check manifest is loaded: **Extensions** → **Wikibase** → **Manage Wikibase instances**
2. Verify MediaWiki container is running: `./mediawiki.sh ps`
3. Test API endpoint from OpenRefine container:
   ```bash
   docker exec openrefine curl http://mediawiki-mediawiki-web-1:8080/w/api.php?action=query
   ```

### No Matches Found
**Problem:** All artist names show "No matches"

**Solution:**
1. Check Q1 exists in Wikibase: http://localhost:8181/wiki/Item:Q1
2. Verify reconciliation endpoint in manifest
3. Try broader search: Remove specific reconciliation type

### Upload Fails with "Permission Denied"
**Problem:** Cannot upload to Wikibase

**Solution:**
1. Re-authenticate in MediaWiki
2. Check Admin user has edit permissions
3. Verify bot passwords are configured (if using bot account)

### Network Errors
**Problem:** "Connection refused" or timeout errors

**Solution:**
1. Verify both containers are on same network:
   ```bash
   docker network inspect nfdi4culture-net
   ```
2. Check MediaWiki API is accessible:
   ```bash
   curl http://localhost:8181/w/api.php
   ```

---

## Expected Results

After completing this workflow, you should have:
- ✅ 20 rows of museum data imported into OpenRefine
- ✅ All artist names reconciled to Q1 (Vincent van Gogh)
- ✅ Multiple location names reconciled to Q3 (MoMA) or marked for new item creation
- ✅ Wikibase schema defined for artwork items
- ✅ (Optional) New items created in Wikibase for each artwork
- ✅ Demonstration of data quality improvement through reconciliation

---

## Next Steps

1. **Expand Dataset:** Add more artists, create Q items for them
2. **Add Properties:** Create P2 (collection), P3 (date), P4 (medium)
3. **Reconcile Dates:** Use OpenRefine's date parsing with Wikibase time values
4. **Link External Sources:** Reconcile to Wikidata, Getty AAT
5. **Automate:** Create OpenRefine workflows for batch processing

---

## Key Learnings

**Data Quality:**
- Reconciliation handles various name formats automatically
- Fuzzy matching works well for entity resolution
- Manual review is still important for edge cases

**Wikibase Integration:**
- Manifest configuration enables custom Wikibase instances
- Schema editor provides flexible entity modeling
- Edit tracking maintains data provenance

**Workflow Efficiency:**
- Bulk operations save time vs. manual data entry
- Facets enable quick filtering and quality control
- Export options support multiple downstream uses
