---
name: skill-creator-1.0.0
description: "Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit or optimize an existing skill, run evals to test a skill, benchmark skill performance, or optimize a skill's description for better triggering accuracy. Also use when the user says 'turn this into a skill', wants to capture a workflow as a reusable skill, or asks how to write a good SKILL.md. Even if they just mention 'skill', 'custom instruction', or 'reusable workflow', consider invoking this."
---

# Skill Creator

A skill for creating new skills and iteratively improving them, tailored for GitHub Copilot in VS Code.

At a high level, the process goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run them via subagents with the skill loaded
- Help the user evaluate the results both qualitatively and quantitatively
- Rewrite the skill based on feedback
- Repeat until satisfied
- Optimize the skill's description for accurate triggering

Your job is to figure out where the user is in this process and help them progress. Maybe they say "I want to make a skill for X" — help narrow it down, draft, test, iterate. Maybe they already have a draft — go straight to eval/iterate. Be flexible: if the user says "just vibe with me, no evals needed", do that instead.

---

## Communicating with the User

Skill creation attracts users across a wide range of technical familiarity. Pay attention to context cues:

- Terms like "evaluation" and "benchmark" are borderline but OK
- For "JSON" and "assertion", look for cues that the user knows these terms before using them without explanation
- It's fine to briefly explain terms if you're in doubt

---

## Creating a Skill

### Step 1: Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow they want to capture (e.g., "turn this into a skill"). If so, extract answers from the conversation history first — the tools used, the sequence of steps, corrections the user made, input/output formats observed. The user may need to fill gaps, and should confirm before proceeding.

Key questions to answer:

1. What should this skill enable the model to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on the skill type, but let the user decide.

Use the `vscode_askQuestions` tool to gather structured input from the user when there are multiple choices to make simultaneously. This is more efficient than asking questions one at a time in chat.

### Step 2: Interview and Research

Proactively ask about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until you've got this part ironed out.

Use available tools for research:
- **`Explore` subagent**: Search the codebase for similar patterns, existing skills, relevant code
- **`search_subagent`**: Find specific files or code snippets
- **`semantic_search`**: Search for relevant documentation or comments

Come prepared with context to reduce burden on the user.

### Step 3: Write the SKILL.md

Based on the user interview, create the skill. The components:

- **name**: Skill identifier (lowercase, hyphens). Must match the directory name exactly (including version suffix, e.g., `my-skill-1.0.0`).
- **description**: This is the primary triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. GitHub Copilot uses semantic matching on this field to decide whether to invoke the skill, so make it descriptive and slightly "pushy". For example, instead of "How to build a dashboard", write "How to build a dashboard. Use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of data, even if they don't explicitly ask for a 'dashboard.'"
- **the rest of the skill :)**

Read `references/skill-writing-guide.md` for detailed guidance on skill structure, writing patterns, and best practices specific to GitHub Copilot.

### Step 4: Place the Skill

Save the skill to `.github/skills/<skill-name>-<version>/SKILL.md`. This is where GitHub Copilot discovers skills. The directory name should be `<skill-name>-<version>` (e.g., `my-skill-1.0.0`), and the `name` field in frontmatter must match the directory name exactly.

If the skill needs reference documents, put them in a `references/` subdirectory. If it needs executable scripts, use a `scripts/` subdirectory.

---

## Skill Writing Guide (Summary)

For the full guide, read `references/skill-writing-guide.md`. Key points:

### Anatomy of a Skill

```
skill-name-1.0.0/
├── SKILL.md          (required — YAML frontmatter + markdown instructions)
└── references/       (optional — detailed docs loaded on demand)
    ├── setup.md
    └── patterns.md
```

### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** — Loaded as needed (unlimited size; scripts can execute without loading)

Keep SKILL.md under 500 lines. If approaching this limit, split detailed content into `references/` files with clear pointers about when to `read_file` them.

### Writing Patterns

- Use imperative form in instructions
- Explain the **why** behind instructions — today's models are smart and respond better to reasoning than rigid MUSTs
- Include examples when they'd reduce ambiguity
- Don't over-constrain with ALWAYS/NEVER unless truly critical

### Principle of Lack of Surprise

Skills must not contain malware, exploit code, or anything that could compromise security. A skill's contents should not surprise the user in their intent if described.

---

## Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts — the kind of thing a real user would actually say. Share them with the user: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json` within the skill's workspace directory. Don't write assertions yet — just the prompts. You'll draft assertions in the next step while the runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema (including the `assertions` field, which you'll add later).

---

## Running and Evaluating Test Cases

This section is one continuous sequence — don't stop partway through. Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Create directories as you go.

### Step 1: Run All Test Cases (with-skill AND baseline)

For each test case, launch two runs — one with the skill, one without.

**With-skill run** — use `runSubagent` to execute the test:

```
Use runSubagent with a prompt like:

"You have access to a skill. Read the skill file at <path-to-SKILL.md> first,
then follow its guidance to complete this task:
<eval prompt>
Input files: <eval files if any, or 'none'>
Save all outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/"
```

**Baseline run** (same prompt, no skill):
- **Creating a new skill**: Run the same prompt without mentioning the skill at all. Save to `without_skill/outputs/`.
- **Improving an existing skill**: Use the old version as the baseline — snapshot the old SKILL.md first, then point the baseline subagent at that snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case. Give each eval a descriptive name based on what it's testing.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

Note: `runSubagent` calls are sequential (not parallel), so each run completes before the next starts.

### Step 2: Draft Assertions

While reviewing test outputs, draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them and explain what they check.

Good assertions are objectively verifiable and have descriptive names — they should read clearly so someone glancing at the results immediately understands what each one checks. Subjective skills (writing style, design quality) are better evaluated qualitatively — don't force assertions onto things that need human judgment.

Update the `eval_metadata.json` files and `evals/evals.json` with the assertions once drafted.

### Step 3: Grade Each Run

For each completed run, grade it by evaluating each assertion against the outputs. You can either:

1. **Grade inline** — read the outputs yourself and evaluate each assertion right in the conversation
2. **Use a subagent** — spawn a `runSubagent` that reads `references/grading-guide.md` and grades the outputs independently (more rigorous, avoids bias since you wrote the skill)

Save grading results to `grading.json` in each run directory. The `grading.json` must use the fields `text`, `passed`, and `evidence` (not other variants). See `references/schemas.md` for the exact format.

For assertions that can be checked programmatically, write and run a script rather than eyeballing it — scripts are faster, more reliable, and can be reused across iterations.

### Step 4: Aggregate and Present Results

After all runs are graded:

1. **Aggregate into a benchmark summary** — create a `benchmark.json` with pass_rate, and per-eval breakdowns for each configuration (with_skill vs without_skill). See `references/schemas.md` for the schema. Also create a `benchmark.md` human-readable summary.

2. **Do an analyst pass** — read the benchmark data and surface patterns the aggregate stats might hide:
   - Assertions that always pass regardless of skill (non-discriminating)
   - High-variance evals (possibly flaky)
   - Specific failure patterns

3. **Present to the user** — show the results directly in the conversation:
   - For each test case: the prompt, key outputs, and grading results
   - The benchmark summary with pass rates and any analyst observations
   - Ask for feedback: "How do these results look? Any specific issues you'd like me to address?"

### Step 5: Collect Feedback

The user provides feedback in conversation. Empty/positive feedback means they're satisfied. Focus improvements on test cases where the user had specific complaints.

---

## Improving the Skill

This is the heart of the loop. You've run the test cases, the user has reviewed the results, and now you need to make the skill better.

### How to Think About Improvements

1. **Generalize from the feedback.** You and the user are iterating on only a few examples because it's fast. But the skill will be used many times across many different prompts. Rather than putting in fiddly overfitty changes or oppressively constrictive MUSTs, if there's a stubborn issue, try branching out — use different metaphors or recommend different working patterns. It's cheap to try.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Read the subagent transcripts (if available), not just final outputs — if the skill is making the model waste time on unproductive steps, trim those parts.

3. **Explain the why.** Try hard to explain the **why** behind everything you're asking the model to do. Today's LLMs are smart. They have good theory of mind and when given a good harness can go beyond rote instructions. If you find yourself writing ALWAYS or NEVER in all caps, that's a yellow flag — reframe and explain the reasoning so the model understands why it's important. That's more humane, powerful, and effective.

4. **Look for repeated work across test cases.** If all test runs independently wrote similar helper scripts or took the same multi-step approach, the skill should bundle that script. Write it once, put it in `scripts/`, and tell the skill to use it.

Take your time here. Write a draft revision, then look at it with fresh eyes and improve it. Really get into the head of the user and understand what they want and need.

### The Iteration Loop

After improving the skill:

1. Apply your improvements to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs. If creating a new skill, the baseline is always `without_skill`. If improving, use your judgment: the original version or the previous iteration.
3. Present results to the user for review
4. Collect feedback, improve again, repeat

Keep going until:
- The user says they're happy
- The feedback is all positive (everything looks good)
- You're not making meaningful progress

---

## Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism that determines whether GitHub Copilot invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

### How Skill Triggering Works

Understanding the triggering mechanism helps design better descriptions. Skills appear in Copilot's available skills list with their name + description, and the model decides whether to consult a skill based on that description. The model only consults skills for tasks it can't easily handle on its own — simple, one-step queries may not trigger a skill even if the description matches perfectly. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

### Step 1: Generate Trigger Eval Queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

The queries must be realistic — concrete, specific, with details like file paths, personal context, column names, URLs. Some might be lowercase, contain abbreviations or typos. Use a mix of lengths, and focus on edge cases rather than clear-cut examples.

**Bad**: `"Format this data"`, `"Extract text from PDF"`
**Good**: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage"`

For **should-trigger** queries (8-10): different phrasings of the same intent — some formal, some casual. Include cases where the user doesn't name the skill explicitly but clearly needs it.

For **should-not-trigger** queries (8-10): near-misses — queries that share keywords or concepts but actually need something different. Don't make them obviously irrelevant.

### Step 2: Review with User

Present the eval set to the user for review. Let them edit queries, toggle should-trigger, add/remove entries. This step matters — bad eval queries lead to bad descriptions.

### Step 3: Run the Optimization Loop

For each eval query, analyze whether the current description would cause the skill to trigger:

1. **Evaluate the current description**: For each query, reason about whether the description's keywords, concepts, and framing would cause semantic matching to select this skill. Rate confidence (high/medium/low).

2. **Identify failures**: Which should-trigger queries wouldn't match? Which should-not-trigger queries would incorrectly match?

3. **Propose an improved description**: Based on the failures, rewrite the description to better capture the intended triggers while excluding false positives.

4. **Re-evaluate**: Run the same analysis on the new description. Did it improve?

5. **Iterate**: Repeat up to 5 times or until the description covers all eval queries well.

Throughout, keep a train/test split mentality: optimize for the queries you've seen, but think about whether the description generalizes to queries you haven't seen.

### Step 4: Apply the Result

Take the best description and update the skill's SKILL.md frontmatter. Show the user before/after and explain the changes.

---

## Reference Files

The `references/` directory has additional documentation. Read them when needed:

- `references/skill-writing-guide.md` — Detailed guide on skill structure, patterns, and best practices for GitHub Copilot
- `references/schemas.md` — JSON structures for evals.json, grading.json, benchmark.json, history.json
- `references/grading-guide.md` — How to evaluate assertions against outputs (for grading subagents or inline grading)

---

## Available Tools

When executing this skill, you have access to these key tools:

| Tool | Use For |
|------|---------|
| `runSubagent` | Run test cases with/without skill, spawn grading agents |
| `Explore` subagent | Fast codebase exploration and research |
| `search_subagent` | Find files by pattern or search code |
| `vscode_askQuestions` | Gather structured input from user (multiple choices at once) |
| `create_file` / `replace_string_in_file` | Write and edit skill files |
| `read_file` | Load reference docs, examine outputs |
| `run_in_terminal` | Execute scripts for programmatic assertion checking |
| `memory` | Store session notes, track iteration history |
| `manage_todo_list` | Track progress through the skill creation workflow |

---

## Core Loop Reminder

For emphasis, the core loop:

1. Figure out what the skill is about
2. Draft or edit the skill
3. Run test prompts via `runSubagent` with the skill loaded
4. With the user, evaluate the outputs:
   - Create benchmark.json and present results for review
   - Run quantitative evals (grading)
5. Repeat until satisfied
6. Optimize the description for triggering accuracy

Add steps to your TodoList to make sure you don't forget. Specifically: "Present graded results to user for review" should always be a tracked step.

Good luck!
