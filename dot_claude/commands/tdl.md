---
description: Create or update todo list entries
---

# Todo List Entry Manager

This command manages persistent personal todos - homelab tasks, household items,
personal projects. Unlike session-based TodoWrite (which tracks engineering work
within a coding session), these persist across sessions with richer metadata:
priority, due dates, project tags, and status history.

All todos are stored in `~/Working/todo/todos.yaml` with the following schema:

```yaml
---
todos:
  - id: 1
    task: "Description of the task"
    status: pending|in_progress|completed|deleted
    priority: low|medium|high
    due_date: 2025-12-31  # ISO 8601, optional
    project: project.subproject  # dot notation for hierarchy
    created_at: 2025-12-27  # ISO 8601
    in_progress_at: 2025-12-28  # optional, when marked in progress
    completed_at: 2025-12-30  # optional, when completed
    deleted_at: 2025-12-30  # optional, when soft deleted
    deleted_reason: "why deleted"  # optional
    tags:  # optional
      - tag1
      - tag2
```

Use Read, Edit, and Write tools to manage this YAML file directly (NOT TodoWrite/TodoRead).

**Project Hierarchy:**
- Use dot notation for nested projects: `homelab.k3s`, `house.garage`, `tools.claude`
- Top-level project comes first, sub-projects follow with dots
- Examples from user's existing todos: `homelab.zigbee`, `house.main bedroom`, `tools.claude`

## Usage

- `/tdl list [query]` - List todos matching query (or all if no query)
  - Group by project with proper nesting (e.g., homelab → homelab.k3s → homelab.zigbee)
  - Include ID, task, status, priority, due date
  - Hide completed items older than 7 days
  - Hide deleted items entirely
  - Use emojis/formatting to distinguish: pending ⏳, in_progress 🔄, completed ✅
  - Format as readable table or structured list

- `/tdl add <task description>` - Add new todo
  - Auto-assign next available ID
  - Set status to "pending"
  - Set created_at to today (ISO 8601)
  - Use AskUserQuestion to ask for: priority, due_date, project, tags
  - If adding multiple items, ask if they share same metadata
  - Return the new todo ID to user

- `/tdl progress <ID or task text>` - Mark as in_progress
  - Find by ID or fuzzy match task text
  - Set status to "in_progress"
  - Set in_progress_at to today

- `/tdl complete <ID or task text>` - Mark as completed
  - Find by ID or fuzzy match task text
  - Set status to "completed"
  - Set completed_at to today

- `/tdl delete <ID or task text>` - Soft delete
  - Find by ID or fuzzy match task text
  - Set status to "deleted"
  - Set deleted_at to today
  - Use AskUserQuestion to ask for deleted_reason

## Implementation Notes

- Read entire `~/Working/todo/todos.yaml` file
- Parse YAML structure
- Make modifications (add, update status, etc.)
- Write back to file using Edit or Write tool
- Always maintain YAML formatting and structure
- Preserve all existing fields when updating entries
