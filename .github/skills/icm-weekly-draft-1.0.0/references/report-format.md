# Weekly Report Format

Mirror the sample weekly report as closely as possible, but keep the markdown readable.

## Target Columns

Use this exact column order:

| Column | Meaning |
| --- | --- |
| Day / time | UTC time for the incident row |
| RP / Run / Reported by customer | Short classification label |
| Severity | ICM severity number |
| Status | ICM state |
| # of customer impact | Customer impact flag or count when available |
| # of occurrence | Hit count or occurrence count when meaningful |
| Root cause | Owner-enriched RCA field, blank by default |
| Bug and/or ICM to external team | One representative incident title with clickable ICM URL; append external escalation only when concise and clearly relevant |
| Error msg | Blank by default in the draft; owner may fill later |
| Notes | Draft cluster summary and transient/manual-review rationale |

## Markdown Table

Use this header for both issue-type sections:

```markdown
| Day / time | RP / Run / Reported by customer | Severity | Status | # of customer impact | # of occurrence | Root cause | Bug and/or ICM to external team | Error msg | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
```

## Formatting Rules

- Keep times in UTC.
- Keep `Severity` as the numeric ICM value.
- Keep `Status` as the exact ICM state string.
- Keep `Root cause` blank unless strong evidence exists.
- Keep `Error msg` blank unless the user explicitly asks for a populated draft.
- Put the clickable sampled incident title in `Bug and/or ICM to external team`.
- Use `Notes` for the cluster summary only.

## Example Row

```markdown
| 2026-02-09 03:58 UTC | Runtime | 3 | MITIGATED |  | 107 |  | [Incident 745248815: [TableErrors] Table requests has continuous failures of Timeout](https://portal.microsofticm.com/imp/v3/incidents/details/745248815/home) |  | Sampled incidents look auto-mitigated and repetitive, so this family can be treated as transient in the draft. Owner should confirm the backend timeout pattern later. |
```

## Section Policy

- `## Transient` should appear first.
- `## Needs Manual Review` should appear second.
- If there are no incidents in a section, state that explicitly instead of omitting the section.
- The report header should include the filtered weekly incident total, the aggregated table total, and a short reconciliation note.