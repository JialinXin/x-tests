# Grading Guide

How to evaluate assertions against execution outputs. Use this guide when grading test runs — either inline or via a `runSubagent` call.

---

## Role

The Grader reviews output files and (optionally) execution context, then determines whether each assertion passes or fails. Provide clear evidence for each judgment.

You have two jobs:
1. **Grade the outputs** against the assertions
2. **Critique the evals themselves** — a passing grade on a weak assertion is worse than useless because it creates false confidence. When you notice an assertion that's trivially satisfied, or an important outcome that no assertion checks, say so.

---

## Inputs

When grading, you need:

- **assertions**: List of assertion statements to evaluate (strings from `eval_metadata.json` or `evals.json`)
- **outputs_dir**: Directory containing output files from the run
- **prompt**: The original task prompt (for understanding intent)

---

## Process

### Step 1: Examine Output Files

1. List all files in the outputs directory
2. Read/examine each file relevant to the assertions
3. Note contents, structure, and quality
4. If outputs aren't plain text, use appropriate tools to inspect them (e.g., run a script to parse JSON, open CSV)

### Step 2: Evaluate Each Assertion

For each assertion:

1. **Search for evidence** in the outputs
2. **Determine verdict**:
   - **PASS**: Clear evidence the assertion is true AND the evidence reflects genuine task completion, not just surface-level compliance
   - **FAIL**: No evidence, evidence contradicts the assertion, or the evidence is superficial (e.g., correct filename but empty/wrong content)
3. **Cite the evidence**: Quote the specific text or describe what you found

### Step 3: Extract and Verify Claims

Beyond the predefined assertions, extract implicit claims from the outputs:

1. **Factual claims** ("The file has 12 entries") — check against actual content
2. **Process claims** ("Used the recommended approach") — verify from output structure
3. **Quality claims** ("All fields were filled correctly") — evaluate substantively

Flag claims that cannot be verified with available information.

### Step 4: Critique the Evals

After grading, consider whether the evals themselves could be improved. Only surface suggestions when there's a clear gap.

Good suggestions test meaningful outcomes — assertions that are hard to satisfy without actually doing the work correctly. Think about what makes an assertion *discriminating*: it passes when the skill genuinely succeeds and fails when it doesn't.

Suggestions worth raising:
- An assertion that passed but would also pass for a clearly wrong output
- An important outcome you observed — good or bad — that no assertion covers
- An assertion that can't actually be verified from the available outputs

Keep the bar high. The goal is to flag things the eval author would say "good catch" about.

---

## Grading Criteria

**PASS when:**
- The outputs clearly demonstrate the assertion is true
- Specific evidence can be cited
- The evidence reflects genuine substance, not just surface compliance

**FAIL when:**
- No evidence found
- Evidence contradicts the assertion
- The assertion cannot be verified from available information
- The evidence is superficial — technically satisfied but the underlying task outcome is wrong
- The output meets the assertion by coincidence rather than by actually doing the work

**When uncertain:** The burden of proof to pass is on the assertion. If you can't find clear evidence, it fails.

---

## Output Format

Save results to `grading.json` using this exact structure:

```json
{
  "expectations": [
    {
      "text": "The output includes the name 'John Smith'",
      "passed": true,
      "evidence": "Found in output.txt line 3: 'Contact: John Smith'"
    },
    {
      "text": "The spreadsheet has a SUM formula in cell B10",
      "passed": false,
      "evidence": "No spreadsheet was created. The output was a text file."
    }
  ],
  "summary": {
    "passed": 1,
    "failed": 1,
    "total": 2,
    "pass_rate": 0.50
  },
  "claims": [
    {
      "claim": "The form has 12 fillable fields",
      "type": "factual",
      "verified": true,
      "evidence": "Counted 12 fields in output JSON"
    }
  ],
  "eval_feedback": {
    "suggestions": [
      {
        "assertion": "The output includes the name 'John Smith'",
        "reason": "A hallucinated document mentioning the name would also pass — consider checking it appears as the primary contact with matching details"
      }
    ],
    "overall": "Assertions check presence but not correctness. Consider adding content verification."
  }
}
```

**Critical:** Use the field names `text`, `passed`, and `evidence` exactly. Other variants (`name`/`met`/`details`) will break downstream processing.

---

## Guidelines

- **Be objective**: Base verdicts on evidence, not assumptions
- **Be specific**: Quote the exact text that supports your verdict
- **Be thorough**: Check all output files, not just the first one
- **Be consistent**: Apply the same standard to each assertion
- **Explain failures**: Make it clear why evidence was insufficient
- **No partial credit**: Each assertion is pass or fail

---

## Programmatic Checking

For assertions that can be checked programmatically (file exists, JSON is valid, specific string present, row count matches), prefer writing and running a script over manual inspection:

```powershell
# Example: Check if output JSON is valid and has expected fields
$json = Get-Content "outputs/result.json" | ConvertFrom-Json
if ($json.contacts -and $json.contacts.Count -ge 5) {
    Write-Output "PASS: JSON has $($json.contacts.Count) contacts (expected >= 5)"
} else {
    Write-Output "FAIL: JSON has $($json.contacts.Count) contacts (expected >= 5)"
}
```

Scripts are faster, more reliable, and can be reused across iterations. Save them in the eval directory for re-use.

---

## Subagent Invocation Template

When spawning a grading subagent via `runSubagent`, use this prompt template:

```
You are a grader evaluating test outputs. Read the grading guide at
<skill-path>/references/grading-guide.md for detailed instructions.

Assertions to evaluate:
<list of assertions>

Outputs directory: <path-to-outputs>
Original prompt: <the eval prompt>

Grade each assertion as PASS or FAIL with evidence.
Save results to <path>/grading.json using the exact schema from the grading guide.
```