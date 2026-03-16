# Notes Synthesis Guide

Generate `Notes` as a draft operator summary, not an RCA.

## Priority Order

Use the best available evidence in this order:
1. ICM discussion or context content
2. Direct incident detail from `mcp_icm_mcp_serve_get_incident_details_by_id`
3. AI summary when non-empty
4. Mitigation hints and similar incidents
5. Title pattern, occurring location, TSG link, and state transitions

If richer evidence is unavailable, still write a useful but cautious draft note.

## How Many Incidents To Sample

For each recurring active family, inspect one or two representative incidents.

Good cases for sampling:
- repeated alerts with the same bracketed family prefix
- repeated incidents in the same region or cluster family
- recurring mitigated alerts that look transient

Do not sample only one incident and then overstate certainty for the entire week.

## Good Draft Notes

Good note patterns:
- `Recurring node connectivity alerts across multiple clusters; sampled incidents show runtime or infrastructure style failures with no clear customer impact yet. Owner should confirm whether this is transient platform noise or a persistent cluster issue.`
- `Sampled mitigated TableErrors incident auto-mitigated via health monitor after repeated healthy signals. Looks transient, but owner should verify if there is a durable backend timeout pattern.`
- `Recurring RP async failures around Redis or resource update paths; sampled incidents suggest retry or dependency behavior, but RCA is still owner-dependent.`

## Avoid

Do not write:
- invented root cause statements
- full stack dumps in the notes cell
- broad claims like `same issue as last week` unless the sampled incidents or similar-incident data supports it

## Error Message Compression

If detail payloads contain very long error text:
- reduce to the first meaningful failure phrase, for example `Redis connection timeout`, `TaskCanceledException during resource update`, or `Node connectivity issue`
- otherwise leave `Error msg` blank and keep the interpretation in `Notes`

## External Team / Bug Column

Fill `Bug and/or ICM to external team` only when evidence clearly shows one of:
- linked partner or dependency incident
- external team ownership handoff
- explicit bug or work item reference

Do not use this column as a second notes field.

## Honesty Rule

When uncertain, say so briefly. Draft quality is acceptable; fabricated precision is not.