# Claude Confluence Workflow Instructions

Instructions for Claude AI on how to handle Confluence page management using Atlassian MCP tools.

## Overview

The Atlassian MCP integration provides access to Confluence for reading, searching, creating, and updating pages. Use it to help maintain documentation based on conversation context.

## Confluence Instance

- **Endpoint**: https://your-org.atlassian.net
- **Cloud ID**: your-cloud-id-here
- **Main Space**: Your Main Space Name

## When to Update Confluence

### Automatically Update (No Confirmation Needed)

**Search and read operations:**
- Searching for content
- Reading page content
- Listing spaces
- Getting comments
- Viewing page metadata

### ALWAYS Ask for Confirmation First

**CRITICAL: Before ANY write operation:**
- **ALWAYS show diffs before updating pages** - User must see exactly what will change
- Creating new pages
- Updating existing pages
- Adding comments
- Any bulk operations

## Update Workflow - MANDATORY

When updating a Confluence page:

1. **Read the current page** to get latest content
2. **Determine changes needed** based on user request
3. **Show ONLY the diffs** - not the full page content:
   ```markdown
   ## Change: Section Name

   **Current:**
   ```
   [old text]
   ```

   **New:**
   ```
   [new text]
   ```
   ```
4. **Ask for confirmation**: "Should I apply this change?"
5. **Only after approval**: Update the page
6. **Confirm success**: Report the new version number and URL

### Deletions — MANDATORY

**Never silently delete content.** This applies to any removal: sections, headings, paragraphs, tables, list items, or panels — even as part of a restructure or simplification.

Before removing anything:
1. **Show exactly what will be deleted** using the same diff format as updates
2. **Explicitly ask**: "Should I delete this content?"
3. **Only delete after explicit approval**

```markdown
## Deletion: Section Name

**Content to be removed:**
[exact text/content being deleted]

Should I delete this?
```

### Example Diff Display

**Good:**
```markdown
## Change: My Team Name

**Current:**
```markdown
**(formerly Old Team Name)**
```

**New:**
```markdown
**(formerly Old Team Name and Other Team Name)**
```

Should I apply this change?
```

**Bad:**
```markdown
Here's the full updated page content:
[Entire 500-line page content...]

Should I update?
```

## Search Guidelines

### Using Rovo Search

Rovo Search is the primary search method:
```
mcp__atlassian__search with query parameter
```

**Use for:**
- Natural language queries
- Broad searches across spaces
- Finding pages by keywords
- Discovering related content

**Examples:**
- "DevOps team structure"
- "SDLC migration documentation"
- "Team A Team B Team C"

### Using CQL Search

Use CQL for precise searches:
```
mcp__atlassian__searchConfluenceUsingCql
```

**Use for:**
- Specific field searches
- Date-based queries
- Type filtering (page, blog, etc.)
- Complex boolean queries

**Examples:**
- `title ~ "My Page" AND space = MySpace`
- `type = page AND lastModified >= "2023-01-01"`

## Reading Pages

### Preferred Format

**Always use ADF (Atlassian Document Format) for reads and writes.** ADF is Confluence's native JSON-based document format and is lossless — it can represent everything the editor produces (merged cells, checkboxes, code blocks, inline links). Markdown is lossy and silently breaks on complex content.

```
contentFormat: "adf"
```

**Only use markdown format when:**
- Quickly scanning page content for research (no update planned)
- User explicitly requests a human-readable summary

### Reading Best Practices

1. **Start with search** to find the page
2. **Get page metadata** (ID, URL, version) from search results
3. **Read full content** with ADF format
4. **Process and understand** before proposing changes

## Updating Pages

### Pre-Update Checklist

Before updating ANY page:
- ✅ Read current page content
- ✅ Identify specific sections to change
- ✅ Prepare diff showing old vs new
- ✅ Show diff to user
- ✅ Get explicit approval
- ✅ Then update

### Update Guidelines

**Keep updates:**
- **Focused** - Only change what's needed
- **Consistent** - Match existing formatting style
- **Clear** - Changes should be obvious from diff
- **Reversible** - User can undo if needed

**Preserve:**
- Existing formatting and structure
- Links and references
- Comments and metadata
- Section organization

### ADF Format: Lessons Learned

**Always use ADF.** Markdown silently breaks on complex content — newlines inside table cells get treated as row separators, merged cells are impossible, and checkboxes/code macros are unsupported. ADF is lossless and works for everything.

#### Matching an example page's style

When the user says "use this page as an example", **fetch the example page in ADF format** before building your own ADF. This reveals the exact node structures for:
- Checkboxes (`taskList`/`taskItem`)
- Code blocks (`codeBlock`)
- Merged cells (`rowspan`/`colspan`)
- Inline links (`inlineExtension`)

#### ADF node reference (confirmed working)

**Checkbox (task list):**
```json
{
  "type": "taskList",
  "attrs": { "localId": "<uuid>" },
  "content": [{
    "type": "taskItem",
    "attrs": { "state": "TODO", "localId": "<uuid>" },
    "content": [{ "text": "Checkbox label", "type": "text" }]
  }]
}
```
- `state: "TODO"` = unchecked, `state: "DONE"` = checked
- Both Topic AND Definition cells can independently contain `taskList` nodes — check the example page, don't assume only one column has checkboxes

**Code block:**
```json
{
  "type": "codeBlock",
  "attrs": { "language": "yaml" },
  "content": [{ "text": "key: value", "type": "text" }]
}
```
Renders as a `ac:structured-macro name="code"` block in Confluence storage format.

**Line break within a cell:**
```json
{ "type": "hardBreak" }
```

**Merged cells (rowspan/colspan):**
```json
{
  "type": "tableCell",
  "attrs": { "colspan": 1, "rowspan": 2, "colwidth": [220] },
  "content": [...]
}
```
Only include the cell in the first row of the span; omit it from subsequent rows entirely.

#### Large ADF responses

Tool results over ~30KB are persisted to disk. Use Python to parse them:
```python
import json
data = json.loads(open('/path/to/tool-result.json').read())
page = json.loads(data[0]['text'])  # unwrap the text wrapper
body_content = page['body']['content']
```

#### ADF body size and the update tool call limit

**Problem:** The `updateConfluencePage` tool requires the full page body as a string parameter. Claude's tool call output is limited to ~8K tokens. A page with images, macros, or migration history can easily exceed this.

**Common cause — `legacy-content` orphan nodes:** When a Confluence page is migrated from the old editor, step/wizard content is preserved as `extension` nodes with `extensionKey: "legacy-content"`. These are **invisible to readers** but can add 10–130KB to the ADF. They appear inside `bodiedExtension` macros (e.g. `ui-steps`).

**Temp file naming — IMPORTANT:** Always include the `pageId` in temp filenames to avoid collisions between concurrent sessions editing different pages:
- Raw fetched body: `/tmp/confluence-<pageId>.json`
- Modified body ready to upload: `/tmp/confluence-<pageId>-updated.json`

**Fix workflow:**
1. Fetch the page in ADF format — if the result is auto-persisted to disk, extract the body first using the **Large ADF responses** pattern above, then save to `/tmp/confluence-{PAGE_ID}.json`:
   ```python
   import json
   PAGE_ID = "123456789"  # replace with actual pageId
   data = json.loads(open('/path/to/tool-result.json').read())  # path shown in tool output
   page = json.loads(data[0]['text'])
   with open(f'/tmp/confluence-{PAGE_ID}.json', 'w') as f:
       json.dump(page['body'], f)
   ```
2. Parse with Python and check node sizes:
   ```python
   import json
   body = json.loads(open(f'/tmp/confluence-{PAGE_ID}.json').read())
   for i, sec in enumerate(body['content']):
       print(f"section[{i}]:", len(json.dumps(sec)), "chars")
   ```
3. Check for `legacy-content` orphan nodes anywhere in the tree:
   ```python
   def count_legacy(node):
       count, size = 0, 0
       if node.get('type') == 'extension' and node.get('attrs', {}).get('extensionKey') == 'legacy-content':
           return 1, len(json.dumps(node))
       for child in node.get('content', []):
           c, s = count_legacy(child)
           count += c; size += s
       return count, size
   print(count_legacy(body))
   ```
4. If `legacy-content` nodes found, strip them recursively — they are invisible to readers and safe to remove:
   ```python
   def strip_legacy(node):
       if isinstance(node, list): return [strip_legacy(n) for n in node]
       if not isinstance(node, dict): return node
       out = {**node}
       if 'content' in out:
           out['content'] = [strip_legacy(n) for n in out['content']
                             if not (n.get('type') == 'extension'
                                     and n.get('attrs', {}).get('extensionKey') == 'legacy-content')]
       return out
   body = strip_legacy(body)
   ```
5. Save the trimmed body using the pageId-based name:
   ```python
   with open(f'/tmp/confluence-{PAGE_ID}-updated.json', 'w') as f:
       json.dump(body, f)
   print(f"New size: {len(json.dumps(body)):,} chars")
   ```
6. Read it back with the Read tool (limit: 25K lines) and pass directly to `updateConfluencePage` — the bottleneck is Claude's tool call output limit (~8K tokens, ~32KB of JSON). After stripping legacy-content, most pages will be well under this.

**If the page is still too large after stripping legacy-content:**

The page is genuinely large (real content, not orphan nodes). The tool call itself cannot carry a 200KB+ body — `updateConfluencePage` requires the full body inline, and Claude's tool call output is capped. Options in order of preference:
1. **Manual paste** — provide the user with the exact diff text and the precise location in the wiki to paste it
2. **Footer comment** — add the note as a `createConfluenceFooterComment` (no body size limit; visible at the bottom of the page)
3. **Split the page** — suggest breaking the page into sub-pages so individual pages are small enough to update programmatically

**OAuth token note:** The stored MCP OAuth token (`~/.claude/.credentials.json`) is scoped to the MCP gateway and expires after ~1 hour. It **cannot** be used for direct Confluence REST API calls. Always update pages through the `mcp__atlassian__updateConfluencePage` tool.

### Version Information

After successful update:
```
✅ Successfully updated [Page Title]
- Version: 82 → 83
- Updated: 2026-02-14T01:32:41.645Z
- URL: https://your-org.atlassian.net/wiki/spaces/MySpace/pages/[ID]
```

## Creating Pages

### When User Requests

When creating a new page:

1. **Confirm details:**
   - Space ID
   - Parent page (optional)
   - Title
   - Content structure

2. **Draft content** and show user:
   ```markdown
   # Proposed Page

   **Space**: MySpace
   **Title**: [Page Title]
   **Parent**: [Parent Page Name] (optional)

   **Content:**
   [Full proposed content]
   ```

3. **Ask for approval**: "Should I create this page?"

4. **Create and report**:
   ```
   ✅ Created new page: [Title]
   - Page ID: [ID]
   - URL: [Full URL]
   ```

### Page Structure

Follow Confluence best practices:
- Clear hierarchical headings (##, ###)
- Bulleted/numbered lists for structure
- Tables for comparisons
- Code blocks for technical content
- Links to related pages

## Comments

### Adding Comments

**Confirm before adding:**
- Show user the comment text
- Get approval
- Add comment
- Report success

**Comment types:**
- **Footer comments**: General page comments
- **Inline comments**: Comments on specific text selections

## Research Workflow

### Multi-Page Research

When researching across multiple pages:

1. **Search broadly** to find relevant pages
2. **Read key pages** for information
3. **Identify patterns** and connections
4. **Synthesize findings** for user
5. **Suggest updates** if information is outdated

### Example Research Flow

```
User: "Find history of team reorganizations"

Claude:
1. Search: "team reorganization Alpha Beta Gamma"
2. Find: Release notes, migration plans, OKRs
3. Read: Multiple pages with team references
4. Identify: Alpha→Platform, Beta→Ops Analytics, Gamma→Platform
5. Report: Summary of findings
6. Suggest: "Should I update the Teams page with this history?"
```

## Page ID Reference

Extract page IDs from URLs:
```
https://your-org.atlassian.net/wiki/spaces/MySpace/pages/123456789/Page+Title
                                                               ^^^^^^^^^
                                                               Page ID
```

Use page IDs for:
- Direct page access
- Update operations
- Getting comments
- Checking descendants

## Error Handling

### Page Not Found

If page doesn't exist:
- Verify page ID is correct
- Check space permissions
- Suggest search to find correct page

### Update Conflicts

If version conflict occurs:
- Re-read page to get latest version
- Re-apply changes to new version
- Show new diff to user
- Get approval again

### Permission Errors

If access denied:
- Confirm user has edit permissions
- Check space restrictions
- Suggest manual update if needed

## Best Practices

### DO

✅ Always show diffs before updates
✅ Use markdown format for readability
✅ Search before creating new pages
✅ Preserve existing page structure
✅ Report success with URLs and version info
✅ Be specific about what changed

### DON'T

❌ Update pages without showing diffs first
❌ Make assumptions about page structure
❌ Create duplicate pages
❌ Overwrite content without reading it first
❌ Use overly verbose page content
❌ Skip version information in confirmations

## Common Use Cases

### Team Documentation

- Update team rosters
- Document reorganizations
- Add historical context
- Link related pages

### Knowledge Base

- Update outdated information
- Add cross-references
- Document decisions
- Archive old content

### Project Documentation

- Create project pages
- Track milestones
- Document architecture
- Link to Jira tickets

## Tools Reference

### Main MCP Tools

```
mcp__atlassian__atlassianUserInfo          # Get user info
mcp__atlassian__getAccessibleAtlassianResources  # Get cloudId
mcp__atlassian__search                      # Rovo search (preferred)
mcp__atlassian__searchConfluenceUsingCql   # CQL search
mcp__atlassian__getConfluenceSpaces        # List spaces
mcp__atlassian__getConfluencePage          # Read page
mcp__atlassian__updateConfluencePage       # Update page
mcp__atlassian__createConfluencePage       # Create page
mcp__atlassian__getPagesInConfluenceSpace  # List pages in space
mcp__atlassian__getConfluencePageFooterComments    # Get comments
mcp__atlassian__createConfluenceFooterComment      # Add comment
mcp__atlassian__getConfluencePageDescendants       # Get child pages
```

### Tool Usage Patterns

**Read operations** (no confirmation needed):
```python
# Search
mcp__atlassian__search(query="DevOps")

# Read page
mcp__atlassian__getConfluencePage(
    cloudId="your-cloud-id-here",
    pageId="your-page-id",
    contentFormat="markdown"
)
```

**Write operations** (MUST show diff and confirm):
```python
# 1. Read current
current = mcp__atlassian__getConfluencePage(...)

# 2. Show diff to user
# ... show changes ...

# 3. Get approval
# ... wait for confirmation ...

# 4. Update
mcp__atlassian__updateConfluencePage(
    cloudId="your-cloud-id-here",
    pageId="your-page-id",
    contentFormat="markdown",
    body="[updated content]"
)
```

## Workflow Examples

### Example 1: Simple Update

```
User: "Add 'formerly Old Team' to Current Team"

Claude:
1. Search for "Teams" page
2. Read page content
3. Show diff:
   **Current:** "## Current Team"
   **New:** "## Current Team\n**(formerly Old Team)**"
4. Ask: "Should I apply this change?"
5. User: "yes"
6. Update page
7. Confirm: "✅ Updated Teams page (v82→v83)"
```

### Example 2: Research and Update

```
User: "Find old team names and update the current page"

Claude:
1. Search for historical references
2. Read multiple pages (releases, migration plans)
3. Identify: Alpha→Platform, Beta→Ops Analytics, Gamma→Platform
4. Show proposed changes:
   - Ops Analytics: add "(formerly Beta Team)"
   - Platform: add "(formerly Alpha Team; Gamma Team merged)"
5. Show diffs for each change
6. Ask: "Should I apply these changes?"
7. User: "yes"
8. Update page
9. Confirm with version info
```

### Example 3: Create New Page

```
User: "Create a page about the SDLC migration process"

Claude:
1. Confirm space: "Which space? MySpace?"
2. Draft content structure
3. Show full proposed page
4. Ask: "Should I create this page?"
5. User: "yes"
6. Create page
7. Report: "✅ Created 'SDLC Migration Process' - [URL]"
```

## Version

Instructions version: 1.2.0
Last updated: 10-03-2026
