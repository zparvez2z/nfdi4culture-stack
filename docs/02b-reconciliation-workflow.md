# OpenRefine Reconciliation Workflow Guide

## Step-by-Step: Reconciling Museum Data to Wikidata

**Note:** This guide reflects the actual Day 2 implementation using Wikidata reconciliation. While a local Wikibase manifest was created, the demonstration used Wikidata's reconci.link service since the local MediaWiki lacks a reconciliation endpoint. The workflow is identical to what would be used with a properly configured Wikibase instance.

### Prerequisites
- OpenRefine running at http://localhost:3333
- Sample data: `data/museum-artworks.csv`
- Internet connection for Wikidata API access

---

## Part 1: Import Data into OpenRefine

### 1. Create New Project via Clipboard
1. Open http://localhost:3333
2. Click **"Create Project"** tab
3. Select **"Clipboard"**
4. Open `data/museum-artworks.csv` in a text editor and copy all content
5. Paste CSV data into OpenRefine's text area
6. Click **"Next »"**

**Why Clipboard?** In Docker environments, direct file access can be restricted. The clipboard method is a reliable workaround.

### 2. Configure Import Settings
- **Character encoding:** UTF-8
- **Parse data as:** CSV / TSV / separator-based files
- **Columns are separated by:** comma
- **Parse cell text into numbers, dates, ...:** Checked
- **Store blank rows:** Unchecked
- **Store blank cells as nulls:** Checked

Click **"Create Project »"**

**Result:** 
- Project created: "Clipboard" (ID: 2522811465384)
- 20 rows loaded
- Columns: id, title, artist, date, location, medium, dimensions
- Artist column shows 12 different name variations

---

## Part 2: Data Cleaning with Clustering

### 1. Open Clustering Dialog
1. Click on the **"artist"** column dropdown (▼)
2. Select **"Edit cells"** → **"Cluster and edit..."**
3. Clustering dialog opens showing potential duplicates

### 2. Configure Clustering Method
- **Method:** Key collision
- **Keying Function:** fingerprint (default)
- Click **"Run"** or wait for auto-detection

### 3. Review Clusters Found

**Cluster 1:** 4 values → "V Van Gogh" (4 rows)
- Values: "V Van Gogh", "V van Gogh", "V. van Gogh", etc.
- Cluster size: 4 rows
- Average length: ~10 characters

**Cluster 2:** 4 values → "Vincent van Gogh" (7 rows)
- Values: "Vincent van Gogh", "vincent van gogh", "Vincent Van Gogh", etc.
- Cluster size: 7 rows
- Average length: ~16 characters

**Cluster 3:** 3 values → "van Gogh" (4 rows)
- Values: "Van Gogh", "van Gogh", "VanGogh"
- Cluster size: 4 rows
- Average length: ~8 characters

### 4. Merge Clusters
1. Select all 3 clusters by checking their boxes
2. Review the "New Cell Value" for each (usually the most common form)
3. Click **"Merge Selected & Close"**

**Result:**
- Notification: "Mass edit 15 cells in column artist"
- Undo/Redo: Now shows 1/1
- Artist names normalized from 12 variations to 3 standard forms
- Data quality significantly improved before reconciliation

---

## Part 3: Reconcile to Wikidata

### 1. Start Reconciliation
1. Click on the **"artist"** column dropdown (▼)
2. Select **"Reconcile"** → **"Start reconciling..."**
3. Choose **"Wikidata reconci.link (en)"** as the service
   - This is bundled with OpenRefine (no configuration needed)
   - Service URL: https://wikidata.reconci.link/en/api

### 2. Configure Reconciliation Settings
- **Reconcile against type:** Select "Q5 (human)" for better accuracy
  - This limits results to person entities
  - Improves matching for artist names
- **Auto-match candidates with high confidence:** Checked ✓
- **Maximum number of results:** 10

Click **"Start Reconciling"**

### 3. Monitor Reconciliation Progress
- OpenRefine queries Wikidata for each unique artist name
- Progress indicator shows in column header
- Process takes 10-30 seconds for 20 rows

### 4. Review Results
Column header now shows reconciliation statistics:
- **"35% matched, 0% new, 65% to be reconciled"**

Cell indicators:
- **Blue hyperlink (Q5582):** Auto-matched to entity
- **Single gray box:** One candidate found, needs review
- **Multiple gray boxes:** Multiple candidates
- **No indicator:** No matches found

### 5. Check Matched Entity
Click on any blue Q5582 link to see:
- **Name:** Vincent van Gogh
- **Description:** Dutch Post-Impressionist painter (1853-1890)
- **Confidence score:** 89-100%
- **Link:** https://www.wikidata.org/wiki/Q5582

### 6. Bulk Match Remaining Cells
1. Click **"artist"** column dropdown
2. Select **"Reconcile"** → **"Actions"** → **"Match each cell to its best candidate"**
3. All "Vincent van Gogh" cells (7 total) now matched to Q5582

**Actual Result:** 
- **Matched:** 7 rows (35%)
- **Unmatched:** 13 rows (variations like "van Gogh", "V Van Gogh" need manual review)
- **Target entity:** Q5582 (Vincent van Gogh)
- **Confidence:** 89-100% for matched cells

---

## Part 4: Analyze with Reconciliation Facets

### 1. Create Judgment Facet
1. Click **"artist"** column dropdown
2. Select **"Facet"** → **"Reconciliation facets"** → **"Judgment facets"**

Facet shows:
- **matched:** 7 (cells successfully reconciled to Q5582)
- **none:** 13 (unmatched cells - variations not exact enough)
- **new:** 0 (no cells marked for new entity creation)

### 2. Create Score Facet
1. Click **"artist"** column dropdown
2. Select **"Facet"** → **"Reconciliation facets"** → **"Best candidate's score"**

Score distribution:
- Range: 59-101
- High scores (89-100): "Vincent van Gogh" exact matches
- Medium scores (59-75): "van Gogh" partial matches
- No score: Unmatched cells

### 3. Filter by Judgment
- Click **"matched"** to see only 7 reconciled rows (Sunflowers, The Bedroom, etc.)
- Click **"none"** to see 13 unreconciled rows needing manual review
- This helps prioritize data cleanup efforts

---

## Part 5: Add Entity Identifiers Column

### 1. Create Column with Entity IDs
1. Click **"artist"** column dropdown
2. Select **"Reconcile"** → **"Add entity identifiers column..."**
3. Dialog opens: "Add column containing entity identifiers on 'artist'"

### 2. Configure New Column
- **New column name:** Type `artist_wikidata_id`
  - Descriptive name indicating these are Wikidata entity references
  - Could also use: `artist_qid`, `artist_entity`, `wikidata_id`
- Click **"OK"**

### 3. Review Results
OpenRefine notification:
- "Create new column artist_wikidata_id based on column artist by filling 7 rows with cell.recon.match.id"
- Undo/Redo: Now shows 4/4 (Import → Cluster → Reconcile → Entity IDs)

### 4. Verify Entity IDs
New column shows:
- **Row 2 (Sunflowers, Vincent van Gogh):** Q5582
- **Row 4 (The Bedroom, Vincent van Gogh):** Q5582
- **Row 5 (Café Terrace, Vincent van Gogh):** Q5582
- **Row 8 (Potato Eaters, Vincent van Gogh):** Q5582
- **+ 3 more matched rows:** Q5582
- **Rows 1, 3, 6, 7, 9, 10...:** (empty - unmatched)

**Why This Matters:**
- Basic CSV export doesn't include reconciliation metadata
- Entity ID column makes links explicit and exportable
- Q numbers enable: SPARQL queries, system integration, Wikibase import

---

## Part 6: Export Reconciled Data

---

## Part 7: Export to CSV with Entity IDs

### 1. Export Reconciled Data
1. Click **"Export"** button (top right)
2. Select **"Comma-separated value"**
3. File downloads as `Clipboard.csv`

### 2. Verify Export Content
Open downloaded CSV and check:
- All original columns present (id, title, artist, date, location, medium, dimensions)
- **New column:** artist_wikidata_id
- Sample rows:
  ```csv
  id,title,artist,artist_wikidata_id,date,location,medium,dimensions
  1,The Starry Night,van Gogh,,1889,Museum of Modern Art,Oil on canvas,73.7 × 92.1 cm
  2,Sunflowers,Vincent van Gogh,Q5582,1888,National Gallery London,oil on canvas,92.1 × 73 cm
  4,The Bedroom,Vincent van Gogh,Q5582,1888,Van Gogh Museum,oil paint,72.4 cm × 91.3 cm
  ```

### 3. Save for Project
```bash
cp Clipboard.csv data/museum-artworks-reconciled.csv
```

### 4. What You've Achieved
✅ **Data cleaned:** 15 cells normalized via clustering  
✅ **Entities matched:** 7 rows linked to Wikidata Q5582  
✅ **Metadata captured:** Entity IDs exported as explicit column  
✅ **Ready for integration:** CSV can now be imported to Wikibase, queried via SPARQL, or used in other systems

---

## Part 8: Additional Export Options

### Export Formats Available
1. Click **"Export"** (top right) for multiple format options:
   - **CSV** - Standard spreadsheet format (what we used)
   - **Excel** - .xlsx format with formatting
   - **HTML Table** - For web display
   - **Wikibase QuickStatements** - For bulk Wikibase uploads
   - **Custom tabular exporter** - Fine-grained control

### Export Project for Reuse
1. Click **"Export"** → **"OpenRefine project archive"**
2. Saves entire project including:
   - Data
   - Reconciliation metadata
   - Undo/Redo history
   - Custom transformations
3. Can be re-imported later to continue work

---

## Troubleshooting

### Wikidata Service Not Available
**Problem:** "Wikidata reconci.link" doesn't appear in reconciliation options

**Solution:**
1. Check Wikidata extension is enabled:
   - Go to **Extensions** in OpenRefine
   - Verify "wikidata" extension shows "bundled: true"
2. Restart OpenRefine if needed:
   ```bash
   ./openrefine.sh down && ./openrefine.sh up -d
   ```
3. Check internet connectivity (Wikidata requires external API access)

### No Matches Found
**Problem:** All artist names show "No matches"

**Solution:**
1. Try clustering first to normalize name variations
2. Use broader reconciliation type (remove "Q5 (human)" constraint)
3. Check spelling - Wikidata requires reasonable similarity
4. Try searching manually: https://www.wikidata.org/w/index.php?search=Vincent+van+Gogh

### Low Match Rate
**Problem:** Only 35% matched (expected more)

**Explanation:**
This is normal! Variations like "van Gogh", "V Van Gogh", "V.V.Gogh" are too abbreviated for auto-matching. Options:
1. **Manually review:** Click each cell, select Q5582
2. **Improve clustering:** Try different keying functions
3. **Normalize names:** Use GREL to expand abbreviations
4. **Bulk match:** After one cell matches, use "Match all identical cells"

### Export Missing Entity IDs
**Problem:** Exported CSV doesn't have Q numbers

**Solution:**
You MUST add entity identifiers column first:
1. **artist** → **Reconcile** → **Add entity identifiers column...**
2. Name it (e.g., "artist_wikidata_id")
3. Then export - Q numbers will be included

---

## Actual Results Achieved

After completing Day 2 workflow:
- ✅ 20 rows imported via clipboard method (Project: "Clipboard", ID: 2522811465384)
- ✅ Data clustering performed: 15 cells normalized from 12 variations to 3 forms
- ✅ Reconciliation to Wikidata: 7 cells matched to Q5582 (Vincent van Gogh)
- ✅ Entity IDs extracted: artist_wikidata_id column created with Q5582 values
- ✅ Reconciled data exported: museum-artworks-reconciled.csv with entity references
- ✅ Complete workflow documented: 8 screenshots captured at key stages
- ✅ Match rate: 35% (7/20 rows) - realistic result showing need for manual review
- ✅ Demonstrated: Data quality improvement, entity resolution, linked open data export

---

## Next Steps (Day 3+)

1. **ANTELOPE Integration:** Deploy terminology service for semantic annotations
2. **Wikibase Import:** Upload reconciled data to create artwork items (Q4-Q23)
3. **Add Properties:** Create P2 (collection), P3 (inception), P4 (medium)
4. **Reconcile Locations:** Match museums to Wikidata entities or create local items
5. **Kompakkt Integration:** Link 3D models to Wikibase entities created from OpenRefine

---

## Key Learnings

**Data Quality Best Practices:**
- ✅ **Cluster before reconciling:** Normalizing data first improves match accuracy significantly
- ✅ **Realistic expectations:** 35% auto-match rate is normal for varied data
- ✅ **Manual review essential:** Fuzzy matching needs human verification for ambiguous cases
- ✅ **Entity ID export:** Must explicitly create column - reconciliation metadata not auto-exported

**Wikidata Reconciliation:**
- ✅ **Bundled service:** Wikidata reconci.link works out-of-the-box with OpenRefine
- ✅ **Type constraints improve accuracy:** Using Q5 (human) filters better than generic search
- ✅ **Confidence scores matter:** 89-100% scores are safe to auto-match, lower need review
- ✅ **Same workflow as Wikibase:** Would work identically with local instance having reconciliation API

**Workflow Efficiency:**
- ✅ **Clipboard import:** Reliable workaround for Docker file access restrictions
- ✅ **Undo/Redo tracking:** Makes experimentation safe (4 operations tracked)
- ✅ **Facets for QA:** Judgment and score facets essential for quality control
- ✅ **Linked open data ready:** Exported CSV with Q numbers enables system integration
