# Skill Writing Guide for GitHub Copilot

Detailed guidance on writing high-quality skills for GitHub Copilot in VS Code.

---

## Skill Discovery & Triggering

GitHub Copilot discovers skills by scanning the `.github/skills/` directory in the workspace. Each subdirectory containing a `SKILL.md` file is recognized as a skill.

### How Triggering Works

1. **Metadata scan**: Copilot reads the YAML frontmatter (`name` + `description`) from every `SKILL.md`
2. **Semantic matching**: When a user sends a message, Copilot matches the intent against all skill descriptions
3. **Skill loading**: If a match is found, the full SKILL.md body is loaded into context
4. **Resource loading**: The skill can instruct the model to `read_file` from `references/` or `scripts/` as needed

The `description` field is the primary triggering mechanism. The body of SKILL.md is only loaded after triggering.

### Writing Effective Descriptions

The description should answer two questions:
1. **What does this skill do?** (capability)
2. **When should it activate?** (trigger conditions)

**Principles:**
- Be slightly "pushy" — err on the side of over-triggering rather than under-triggering, because Copilot tends to be conservative about invoking skills
- Include synonyms and alternative phrasings for the same concept
- Mention specific user phrases that should trigger the skill
- Keep it under ~150 words (it's always in context)

**Good example:**
```yaml
description: "Create new skills, modify and improve existing skills, and measure
skill performance. Use when users want to create a skill from scratch, edit or
optimize an existing skill, run evals to test a skill, or optimize a skill's
description for better triggering. Also use when the user says 'turn this into
a skill', wants to capture a workflow as a reusable skill, or asks how to write
a good SKILL.md."
```

**Bad example:**
```yaml
description: "A tool for making skills."
```

The bad example doesn't specify trigger conditions, uses vague language, and won't match many relevant queries.

---

## Directory Structure

### Naming Convention

```
.github/skills/<skill-name>-<version>/
```

- `skill-name`: Lowercase, hyphens only (e.g., `data-transformer`, `code-reviewer`)
- `version`: Semantic versioning suffix (e.g., `1.0.0`, `2.1.3`)
- The YAML `name` field must match the full directory name (e.g., `my-awesome-skill-1.0.0`)
- Example: `.github/skills/my-awesome-skill-1.0.0/` → `name: my-awesome-skill-1.0.0`

### File Organization

```
skill-name-1.0.0/
├── SKILL.md              (required)
│   ├── YAML frontmatter  (name, description required; version, metadata optional)
│   └── Markdown body      (instructions, workflows, examples)
├── references/            (optional — detailed docs loaded on demand)
│   ├── setup-guide.md
│   ├── patterns.md
│   └── schemas.md
├── scripts/               (optional — executable code)
│   ├── transform.py
│   └── validate.sh
└── assets/                (optional — templates, icons, static files)
    └── report-template.md
```

### YAML Frontmatter

Required fields:
```yaml
---
name: skill-name-1.0.0    # Must match the directory name exactly
description: "..."        # Primary trigger mechanism, include when-to-use
---
```

Optional fields:
```yaml
---
name: my-skill-2.0.0
description: "..."
metadata:                  # Additional structured data (rarely needed)
  category: development
---
```

Supported frontmatter attributes: `name`, `description`, `metadata`, `compatibility`, `license`, `argument-hint`, `user-invocable`, `disable-model-invocation`. Note: `version` is NOT a supported attribute — encode the version in the directory and skill name instead.

---

## Progressive Disclosure

Skills use a three-level loading hierarchy:

### Level 1: Metadata (~100 words, always loaded)
The YAML frontmatter. This is always in context for every conversation, so keep it concise but descriptive.

### Level 2: SKILL.md Body (<500 lines, loaded when triggered)
The main instructions. This is loaded when Copilot decides the skill is relevant. Should be self-contained enough to be useful without reading reference files for the most common use cases.

### Level 3: Bundled Resources (unlimited, loaded on demand)
Files in `references/`, `scripts/`, `assets/`. The SKILL.md body should contain clear pointers about when and why to read each reference file.

**Example of a good pointer:**
```markdown
For detailed JSON schema definitions, read `references/schemas.md`.
```

**Example of a bad pointer:**
```markdown
See the references directory for more info.
```

### When to Split Content

Split into `references/` when:
- SKILL.md exceeds ~400 lines
- A section is only needed for specific sub-workflows (e.g., "advanced configuration")
- Large examples, templates, or schemas would bloat the main file
- Different variants exist (e.g., `references/aws.md`, `references/gcp.md`)

### Domain Organization

When a skill supports multiple domains or frameworks:
```
cloud-deploy-1.0.0/
├── SKILL.md              (workflow + selection logic)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
The SKILL.md contains the decision logic ("if the user mentions AWS, read references/aws.md") and only the relevant reference gets loaded.

---

## Writing Patterns

### Imperative Instructions
Use imperative form:
- Good: "Read the input file and extract all email addresses"
- Bad: "The skill should read the input file and extract email addresses"

### Defining Output Formats

Be explicit about expected structure:
```markdown
## Report Structure
ALWAYS use this exact template:
# [Title]
## Executive Summary
## Key Findings
## Recommendations
```

### Including Examples

Examples dramatically reduce ambiguity. Format them clearly:
```markdown
## Commit Message Format

**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication

**Example 2:**
Input: Fixed crash when uploading empty files
Output: fix(upload): handle empty file edge case
```

### Quick Reference Tables

For decision-making workflows, a lookup table is more scannable than prose:
```markdown
## Quick Reference
| Situation | Action |
|-----------|--------|
| User wants new skill | Start from Capture Intent |
| User has draft skill | Skip to Test Cases |
| User wants to improve | Start from Evaluation |
```

### Explaining the Why

Instead of rigid constraints:
```markdown
❌ "NEVER use more than 3 assertions per test case."
✅ "Keep assertions to 2-3 per test case — more than that usually means
   the test is checking too many things at once, which makes failures
   harder to diagnose and makes the eval brittle."
```

---

## Common Patterns and Anti-Patterns

### Good Patterns

1. **Workflow skills**: Step-by-step procedures with clear decision points
2. **Template skills**: Standardize output formats across a project
3. **Research skills**: Structured approaches to investigating topics
4. **Transform skills**: Convert data from one format to another

### Anti-Patterns to Avoid

1. **Kitchen sink skill**: Trying to do everything — split into focused skills
2. **Rigid script skill**: Too prescriptive, no room for model judgment — explain intent instead
3. **Context bomb**: Loading too much into SKILL.md body — use progressive disclosure
4. **Echo skill**: Just restating what the model already knows — add genuine domain knowledge
5. **Stale skill**: References to tools, APIs, or patterns that no longer exist

---

## Real Examples from This Workspace

### Simple Skill: skill-vetter-1.0.0

A single-file skill (SKILL.md only) focused on one workflow: security-first vetting.

**What it does well:**
- Clear step-by-step protocol (Source → Code Review → Permission Scope → Risk Classification)
- Concrete checklists (red flags, permission questions)
- Structured output format (vetting report template)
- Quick reference commands for GitHub repos

**Structure:** Just `SKILL.md` + `_meta.json` — no references needed because the content fits comfortably in one file.

### Complex Skill: self-improving-agent-3.0.1

A multi-file skill with `references/`, `scripts/`, `assets/`, and `hooks/`.

**What it does well:**
- Core workflow in SKILL.md, detailed examples in `references/examples.md`
- Setup guides for different platforms in `references/hooks-setup.md` and `references/openclaw-integration.md`
- Reusable shell scripts in `scripts/` for hook activation and error detection
- Templates in `assets/` for bootstrapping new learning entries

**Structure:** Uses progressive disclosure — SKILL.md gives the quick reference table and core workflow, then points to reference files for specifics.

---

## Checklist: Before Publishing a Skill

- [ ] `name` in frontmatter matches directory name (without version)
- [ ] `description` includes both capability AND trigger conditions
- [ ] SKILL.md is under 500 lines
- [ ] All referenced files (`references/`, `scripts/`) actually exist
- [ ] No hardcoded paths — use relative paths from the skill directory
- [ ] No security red flags (no credentials, no external data exfiltration)
- [ ] Examples are realistic and diverse
- [ ] Instructions explain the why, not just the what
- [ ] Quick reference table for common scenarios (if applicable)
