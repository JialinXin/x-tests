# JSON Schemas

JSON structures used by skill-creator for evaluation and iteration tracking.

---

## evals.json

Defines the evals for a skill. Located at `evals/evals.json` within the skill's workspace directory.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's example prompt",
      "expected_output": "Description of expected result",
      "files": ["evals/files/sample1.pdf"],
      "expectations": [
        "The output includes X",
        "The skill used script Y"
      ]
    }
  ]
}
```

**Fields:**
- `skill_name`: Name matching the skill's frontmatter `name` field
- `evals[].id`: Unique integer identifier
- `evals[].prompt`: The task to execute
- `evals[].expected_output`: Human-readable description of success
- `evals[].files`: Optional list of input file paths (relative to skill root)
- `evals[].expectations`: List of verifiable assertion statements

---

## eval_metadata.json

Per-eval metadata file. Located at `<workspace>/iteration-<N>/eval-<ID>/eval_metadata.json`.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": [
    "The output file contains a valid JSON array",
    "Each item has a 'name' and 'email' field"
  ]
}
```

**Fields:**
- `eval_id`: Numeric eval identifier
- `eval_name`: Human-readable name (used as directory name and report header)
- `prompt`: The task prompt
- `assertions`: List of verifiable statements to grade against

---

## grading.json

Output from grading a run. Located at `<run-dir>/grading.json`.

```json
{
  "expectations": [
    {
      "text": "The output includes the name 'John Smith'",
      "passed": true,
      "evidence": "Found in output file line 3: 'Contact: John Smith'"
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
        "reason": "A hallucinated document mentioning the name would also pass — consider checking it appears as the primary contact"
      }
    ],
    "overall": "Assertions check presence but not correctness."
  }
}
```

**Fields:**
- `expectations[]`: Graded expectations with evidence
  - `text`: The original expectation text (MUST use this field name)
  - `passed`: Boolean — true if expectation passes (MUST use this field name)
  - `evidence`: Specific quote or description supporting the verdict (MUST use this field name)
- `summary`: Aggregate pass/fail counts
  - `passed`: Count of passed expectations
  - `failed`: Count of failed expectations
  - `total`: Total expectations evaluated
  - `pass_rate`: Fraction passed (0.0 to 1.0)
- `claims`: Extracted and verified claims from the output
  - `claim`: The statement being verified
  - `type`: "factual", "process", or "quality"
  - `verified`: Boolean
  - `evidence`: Supporting or contradicting evidence
- `eval_feedback`: Optional improvement suggestions for the evals
  - `suggestions`: Concrete suggestions with `reason` and optional `assertion` reference
  - `overall`: Brief assessment of eval quality

**Important:** The field names `text`, `passed`, and `evidence` must be used exactly. Do not substitute with `name`/`met`/`details` or other variants.

---

## benchmark.json

Aggregated benchmark results across all evals and configurations. Located at `<workspace>/iteration-<N>/benchmark.json`.

```json
{
  "metadata": {
    "skill_name": "my-skill",
    "skill_path": ".github/skills/my-skill-1.0.0",
    "timestamp": "2026-03-12T10:30:00Z",
    "evals_run": [1, 2, 3]
  },
  "runs": [
    {
      "eval_id": 1,
      "eval_name": "extract-contacts",
      "configuration": "with_skill",
      "result": {
        "pass_rate": 0.85,
        "passed": 6,
        "failed": 1,
        "total": 7,
        "errors": 0
      },
      "expectations": [
        {"text": "...", "passed": true, "evidence": "..."}
      ]
    }
  ],
  "run_summary": {
    "with_skill": {
      "pass_rate": {"mean": 0.85, "stddev": 0.05}
    },
    "without_skill": {
      "pass_rate": {"mean": 0.35, "stddev": 0.08}
    },
    "delta": {
      "pass_rate": "+0.50"
    }
  },
  "notes": [
    "Assertion 'Output is a PDF file' passes 100% in both configurations — may not differentiate skill value",
    "Without-skill runs consistently fail on table extraction expectations"
  ]
}
```

**Fields:**
- `metadata`: Information about the benchmark run
  - `skill_name`, `skill_path`, `timestamp`, `evals_run`
- `runs[]`: Individual run results
  - `eval_id`: Numeric eval identifier
  - `eval_name`: Human-readable eval name
  - `configuration`: Must be `"with_skill"` or `"without_skill"` (exact strings)
  - `result`: Nested object with `pass_rate`, `passed`, `failed`, `total`, `errors`
  - `expectations`: Array of graded expectations
- `run_summary`: Statistical aggregates per configuration
  - Each config contains `pass_rate` with `mean` and `stddev`
  - `delta`: Difference strings like `"+0.50"`
- `notes`: Analyst observations

---

## history.json

Tracks version progression across iterations. Located at workspace root.

```json
{
  "started_at": "2026-03-12T10:30:00Z",
  "skill_name": "my-skill",
  "current_best": "v2",
  "iterations": [
    {
      "version": "v0",
      "parent": null,
      "expectation_pass_rate": 0.65,
      "grading_result": "baseline",
      "is_current_best": false
    },
    {
      "version": "v1",
      "parent": "v0",
      "expectation_pass_rate": 0.75,
      "grading_result": "won",
      "is_current_best": false
    },
    {
      "version": "v2",
      "parent": "v1",
      "expectation_pass_rate": 0.85,
      "grading_result": "won",
      "is_current_best": true
    }
  ]
}
```

**Fields:**
- `started_at`: ISO timestamp
- `skill_name`: Name of the skill being improved
- `current_best`: Version identifier of the best performer
- `iterations[].version`: Version identifier (v0, v1, ...)
- `iterations[].parent`: Parent version this was derived from
- `iterations[].expectation_pass_rate`: Pass rate from grading
- `iterations[].grading_result`: "baseline", "won", "lost", or "tie"
- `iterations[].is_current_best`: Whether this is the current best version

---

## trigger_eval.json

Eval set for description optimization. Located at workspace root or `evals/` directory.

```json
[
  {
    "query": "ok so my boss sent me this xlsx file and she wants me to add a profit margin column",
    "should_trigger": true
  },
  {
    "query": "how do I install numpy in my virtual environment?",
    "should_trigger": false
  }
]
```

**Fields:**
- `query`: A realistic user prompt
- `should_trigger`: Whether the skill should activate for this query
