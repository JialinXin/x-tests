# Notes Synthesis Guide

Generate `Notes` as a draft operator summary, not an RCA.

Put the sampled incident title + URL in `Bug and/or ICM to external team`, not in `Notes`.

## Priority Order

Use the best available evidence in this order:
1. ICM discussion or context content
2. Direct incident detail from `mcp_icm_mcp_serve_get_incident_details_by_id`
3. AI summary when non-empty
4. Mitigation hints and similar incidents
5. Title pattern, occurring location, TSG link, and state transitions

If richer evidence is unavailable, still write a useful but cautious draft note.

## How Many Incidents To Sample

For each recurring family, inspect one or two representative incidents.

Good cases for sampling:
- repeated alerts with the same bracketed family prefix
- repeated incidents in the same region or cluster family
- recurring mitigated alerts that look transient
- low-volume or long-lived families that may need manual review

Do not sample only one incident and then overstate certainty for the entire week.

## Good Draft Notes

Good note patterns:
- `Recurring node connectivity alerts across multiple clusters; sampled incidents are mostly mitigated and repetitive, so this family can be treated as transient unless owners find a persistent regional pattern.`
- `Sampled TableErrors incidents were auto-mitigated after repeated healthy signals. Looks transient in this draft, but owner should verify whether there is a durable backend timeout pattern.`
- `Recurring RP async failures around Redis or resource update paths remain uncommon in this window, so the family should stay under manual review until owners confirm whether this is retry noise or a real dependency issue.`

## Avoid

Do not write:
- invented root cause statements
- full stack dumps in the notes cell
- broad claims like `same issue as last week` unless the sampled incidents or similar-incident data supports it
- incident title links duplicated in `Notes`

## Error Message Compression

Leave `Error msg` blank by default.

If the user later explicitly asks for a populated error column and detail payloads contain very long error text:
- reduce to the first meaningful failure phrase, for example `Redis connection timeout`, `TaskCanceledException during resource update`, or `Node connectivity issue`
- otherwise keep `Error msg` blank and keep the interpretation in `Notes`

## Sample Incident Column

Use `Bug and/or ICM to external team` to hold one representative incident title + clickable URL for each cluster.

If there is also a true external escalation, linked bug, or partner incident, append it only when concise and clearly relevant.

Do not use this column as a second notes field beyond the sampled incident reference.

## Draft Classification Cues

When deciding what `Notes` should emphasize:
- call out that a family looks `Transient` when it is high-volume, repetitive, and mostly mitigated in the sampled incidents
- call out that a family `Needs manual review` when it is small, unusual, mixed, or still active after a long duration
- say explicitly when the judgment is based on sampled incidents rather than complete discussion access

## Honesty Rule

When uncertain, say so briefly. Draft quality is acceptable; fabricated precision is not.