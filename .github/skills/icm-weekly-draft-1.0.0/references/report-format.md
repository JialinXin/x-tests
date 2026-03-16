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
| Bug and/or ICM to external team | External escalation, linked bug, or partner ICM |
| Error msg | Short error summary only |
| Notes | Draft note and clickable incident title |

## Markdown Table

Use this header for both active and mitigated sections:

```markdown
| Day / time | RP / Run / Reported by customer | Severity | Status | # of customer impact | # of occurrence | Root cause | Bug and/or ICM to external team | Error msg | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
```

## Formatting Rules

- Keep times in UTC.
- Keep `Severity` as the numeric ICM value.
- Keep `Status` as the exact ICM state string.
- Keep `Root cause` blank unless strong evidence exists.
- Keep long stack traces out of `Error msg`; compress to a phrase or leave blank.
- Put the clickable incident title in `Notes` when there is no better column to hold it cleanly.

## Example Row

```markdown
| 2026-02-09 03:58 UTC | Runtime | 3 | MITIGATED |  | 107 |  |  | Timeout on table requests | [Incident 745248815: [TableErrors] Table requests has continuous failures of Timeout](https://portal.microsofticm.com/imp/v3/incidents/details/745248815/home). Sampled as likely transient and auto-mitigated; owner should confirm root cause from discussion. |
```

## Section Policy

- `## Active Incidents` should appear first.
- `## Mitigated Incidents` should appear second.
- If there are no incidents in a section, state that explicitly instead of omitting the section.