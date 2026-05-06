---
name: gmail-triage
description: "Use when triaging, cleaning, or organizing Gmail inbox — fetches unread messages in batches, classifies them into existing Gmail labels, surfaces action items, and archives on user approval. Triggers on: /triage, 'triage my email', 'clean up my inbox', 'organize my gmail'."
user-invocable: true
metadata:
  version: 2.0.0
  openclaw:
    category: productivity
    requires:
      bins: [gws]
---

# Gmail Triage

Batch-triage unread Gmail inbox messages: discover labels, classify by best match, surface action items, archive on user approval.

## Prerequisites

- `gws` CLI must be authenticated
- Test with: `gws gmail users getProfile --params '{"userId": "me"}' 2>&1 | tail -n +2`
- If auth fails (401), tell the user to run `! gws gmail users getProfile --params '{"userId": "me"}'` to re-authenticate interactively

## Workflow

### Step 1: Load or build label map

**Always re-fetch labels at the start of each triage session.** Label IDs change when labels are deleted and recreated.

```bash
gws gmail users labels list --params '{"userId": "me"}' 2>&1 | tail -n +2
```

From the response, build a label map JSON object. Include only `user` type labels (skip `system` labels like INBOX, SENT, SPAM, etc.).

**If the user has no custom labels at all**, stop and tell them: "You don't have any Gmail labels set up. I need at least a catchall label (for newsletters/low-priority) to triage into. Want me to create one, or would you prefer to set up labels in Gmail first?"

Schema:

```json
{
  "labels": {
    "<label_id>": { "name": "<label_name>" }
  },
  "catchall": "<id of the label to use when nothing specific matches>",
  "junk": "<id of the label to use for actual spam>"
}
```

The `catchall` should be whichever label the user uses for low-priority/newsletter content (e.g., "Clutter", "Low Priority", "Newsletters"). The `junk` label is for actual spam. If unsure which labels serve these roles, **ask the user**.

Save to a session-local temp file (e.g., `/tmp/gmail-triage-labels.json`). This is a session cache, not persistent config — it's rebuilt each session.

### Step 2: Load user preferences

Check for `~/.claude/gmail-triage-prefs.json`. If it exists, read it. Schema:

```json
{
  "neverFlag": ["label name or pattern to never flag as action-needed"],
  "alwaysArchive": ["label name or pattern to archive without asking"],
  "customRules": ["plain-English rules, e.g. 'All bills are autopaid'"],
  "batchSize": 100
}
```

All fields are optional. If the file doesn't exist, proceed with defaults (no custom rules, batch size 100). If the user states a preference during the session (e.g., "don't flag Patient Gateway"), offer to save it to this file for next time.

### Step 3: Fetch message IDs

```bash
gws gmail users messages list \
  --params '{"userId": "me", "q": "is:inbox is:unread", "maxResults": <batchSize>}' \
  --format json 2>&1 | tail -n +2
```

Extract message IDs. Save to a temp file for the current batch.

### Step 4: Fetch message metadata

For each message ID, fetch metadata:

```bash
gws gmail users messages get \
  --params '{"userId": "me", "id": "<msgId>", "format": "metadata", "metadataHeaders": ["From", "Subject", "Date"]}'
```

Use a Python script to iterate and extract: messageId, snippet, from, subject, date. Save results to a temp file.

**Parallelism note:** This is the slowest step (~2 min for 100 messages). No way around it — Gmail has no bulk-get endpoint.

### Step 5: Classify messages

**Goal:** Assign each message to exactly one user label and flag messages requiring user action.

**Preferred: Use a subagent.** Spawn one via the Agent tool (e.g., `subagent_type: "ed3d-basic-agents:sonnet-general-purpose"` or any available general-purpose agent). Pass it:
- The label map file path
- The message details file path
- The classification prompt (see below)

**Why a subagent:** The message details file can be 50-80KB. Offloading to a subagent keeps the main conversation context clean. The subagent reads the files, does the classification, and returns structured JSON.

**Fallback: Classify inline.** If the Agent tool call fails (plugin not installed, subagent type not found), classify the messages yourself. Read the details file in chunks if needed. When classifying inline, reduce batch size to 50 for the remainder of the session to manage context.

#### Classification prompt

Pass this to the subagent (or follow it yourself for inline classification):

```
Read these two files completely:
1. <path to label map> — JSON mapping of Gmail label IDs to names
2. <path to message details> — JSON array of messages with messageId, snippet, from, subject, date

Categorize each message into the single best-matching label from the label map.

Rules:
- Pick the MOST SPECIFIC label that matches the sender or content.
  For example, if there's a label whose name matches the sender's
  company or service, use that label over a generic one.
- If nothing specific fits, use the catchall label (ID: <catchall_id>)
  for newsletters, promotions, and notifications. Use the junk label
  (ID: <junk_id>) only for actual spam.
- Flag messages needing USER ACTION: needs a reply, has a deadline,
  requires a decision, or is time-sensitive. Be conservative.
- Do NOT flag as action-needed: delivered orders, FYI newsletters,
  or security alerts for recognized sign-ins.
- DO flag bill statements and payment-due notices as action-needed
  unless user preferences explicitly say otherwise.
- Mark messages for TRASH (not archive) when appropriate: expired
  verification codes, past calendar invitations. Set a "trash" field
  to true in the output for these.
<if user preferences exist, insert them here as additional rules>

Output ONLY a raw JSON array (no markdown, no commentary):
[
  {
    "messageId": "...",
    "from": "...",
    "subject": "...",
    "label": "<label_id>",
    "labelName": "<human name>",
    "needsAction": true/false,
    "actionNote": "brief note if true, null otherwise",
    "trash": true/false
  }
]
```

Replace `<catchall_id>`, `<junk_id>`, and `<path>` placeholders with actual values from the label map.

### Step 6: Present results and get approval

**NEVER archive without user approval.**

1. Show messages flagged as `needsAction: true` in a table with From, Subject, and action note.
2. Show messages flagged as `trash: true` in a separate table (expired codes, past calendar invites, etc.).
3. Show a summary of label counts for the rest of the batch.
4. Ask the user: proceed with archive+trash, keep specific messages in inbox, or skip this batch.

Track any message IDs the user wants to keep in inbox — these will reappear in the next batch's fetch. Maintain a skip-set for the session.

### Step 7: Archive and trash approved messages

Three actions, executed in parallel:

**Archive** (messages with `trash: false`): Group by label, batch-modify:

```bash
gws gmail users messages batchModify --params '{"userId": "me"}' \
  --json '{"ids": [...], "addLabelIds": ["<label_id>"], "removeLabelIds": ["INBOX"]}'
```

**Trash** (messages with `trash: true`): Batch-modify to move to trash:

```bash
gws gmail users messages batchModify --params '{"userId": "me"}' \
  --json '{"ids": [...], "addLabelIds": ["TRASH"], "removeLabelIds": ["INBOX"]}'
```

**Keep** (messages the user asked to keep): Skip — they stay in inbox.

**After processing**, save a checkpoint: write the list of processed message IDs to a temp file. If auth fails during this step, you know which messages still need processing on retry.

### Step 8: Report and continue

Report: messages archived this batch, running total, label distribution.

If there are more unread messages, offer to continue. The skip-set carries forward across batches.

## Error Handling

### Auth failure (401)

Can happen at any step. Recovery depends on where it failed:

| Failed at | Recovery |
|-----------|----------|
| Step 1 (labels) | Re-auth, restart from step 1 |
| Step 3-4 (fetch) | Re-auth, restart current batch from step 3 |
| Step 5 (classify) | No API calls — won't fail here |
| Step 7 (archive) | Re-auth, retry only the batch-modify calls that failed. Already-classified data is still valid. |

### batchModify errors

If a label ID is invalid (label was deleted), the API returns an error. Surface it to the user: "Label '<name>' (ID: <id>) no longer exists. Should I skip these messages or assign a different label?"

### Partial batch success

`batchModify` is all-or-nothing per call. If it fails, no messages in that call were modified. Since we group by label (one call per label), a failure affects only that label group. Retry the failed group after fixing the issue; other groups already succeeded.

## User Preference Persistence

When the user states a preference during triage:
1. Apply it immediately for the current session
2. Ask: "Want me to save this for future triage sessions?"
3. If yes, upsert into `~/.claude/gmail-triage-prefs.json`

Examples of saveable preferences:
- "All my bills are autopaid" → `customRules: ["All bill statements are autopaid — do not flag as action-needed"]`
- "Don't flag Patient Gateway" → `neverFlag: ["Patient Gateway"]`
- "Auto-archive all Kickstarter" → `alwaysArchive: ["Kickstarter"]`

**`alwaysArchive` requires a matching classification rule.** The `alwaysArchive` list only controls whether to skip the approval prompt — the classifier still needs to know what label to assign. Whenever you add a sender/pattern to `alwaysArchive`, also add a corresponding entry to `customRules` that tells the classifier which label to use. Example:
- `alwaysArchive: ["Microsoft Alumni Network"]`
- `customRules: ["Emails from Microsoft Alumni Network should be labeled as Microsoft."]`

Without the custom rule, the classifier may fall through to Clutter, and the auto-archive fires on the wrong label.

**Upsert semantics:** Read the existing file, merge arrays (append new items, deduplicate), write back. Never overwrite the whole file — the user may have preferences from previous sessions.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Hardcoding label IDs | Always discover IDs from Gmail API at session start |
| Archiving without approval | Present action items and wait for explicit go-ahead |
| Caching labels across sessions | Re-fetch every session; labels change |
| Assuming label names are stable | Match by name but handle "not found" gracefully |
| Baking user preferences into the skill | Store in prefs file, merge at runtime |
| Adding to `alwaysArchive` without a classification rule | Always pair with a `customRules` entry specifying the target label |
