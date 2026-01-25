---
description: Structured research workflow
---

# Research Workflow

This command helps you conduct structured research and document findings.

Use this for in-depth research on technologies, libraries, solutions, or topics that require gathering information from multiple sources.

## Research Process

1. **Define scope** - What are you researching and why?
2. **Gather information** - Use WebSearch, MCP tools (Context7, GitHub, Perplexity)
3. **Document findings** - Create structured markdown in appropriate location
4. **Synthesize** - Summarize key takeaways and next steps

## Where to Save Research

Depends on the purpose:

- **Project-specific research** → `~/Working/projects/<project-name>/research-<topic>.md`
  - When research is for a specific ongoing project
  - Helps keep project context together

- **General reference** → `~/Working/memories/<topic>.md`
  - When research produces reusable knowledge
  - For long-term reference independent of specific project

- **Exploratory** → `~/Working/ideas/<topic>.md`
  - When researching to evaluate if something is worth pursuing
  - Might turn into project or memory later

## File Structure

```markdown
---
date: 2025-12-27
category: research
project: optional-project-name
labels:
  - technology
  - evaluation
---

# Research: <Topic>

## Objective

What I'm trying to learn/decide/understand...

## Sources

- [Source 1 Title](url) - Brief note about what it covers
- [Source 2 Title](url) - Brief note

## Findings

### Key Point 1

Details and notes...

### Key Point 2

Details and notes...

## Examples & Code Snippets

Relevant examples discovered during research...

## Pros & Cons (if evaluating)

**Pros:**
- Point 1
- Point 2

**Cons:**
- Point 1
- Point 2

## Conclusion / Next Steps

Summary of findings and what to do next...
```

## Usage

- `/research <topic>` - Start structured research
  - Use AskUserQuestion to clarify: project association? where to save?
  - Use WebSearch for general information
  - Use Context7 for library documentation
  - Use GitHub MCP for repository research
  - Use Perplexity for complex reasoning/comparison
  - Document findings in structured format
  - Ask user for labels when creating file

- `/research continue <topic or filename>` - Continue existing research
  - Find existing research file
  - Append new findings
  - Update conclusion/next steps

## Research Tools

**WebSearch** - Use for:
- Current information and recent updates
- General knowledge queries
- News and announcements
- Community opinions and discussions

**Context7 MCP** - Use for:
- Library API documentation
- Code examples for specific libraries
- Official documentation lookup
- Version-specific information

**GitHub MCP** - Use for:
- Repository README and documentation
- Code structure and patterns
- Issues and discussions
- Examples from real projects

**Perplexity MCP** - Use for:
- Complex comparisons (Library A vs Library B)
- Reasoning about trade-offs
- Deep analysis requiring multiple sources
- Synthesizing information from various sources

## Behavior

- Always cite sources with URLs
- Keep research focused on stated objective
- Document both what works and what doesn't
- Include code examples when relevant
- Conclude with actionable next steps
- Suggest creating memory, idea, or project based on findings
