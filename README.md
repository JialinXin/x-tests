# x-tests

## Repository Purpose
- Capture repeatable workflows for each task family under `output/`.
- Log individual execution results as timestamped markdown files for traceability.
- Provide a lightweight knowledge base that agents can follow when performing the tasks.

## Directory Structure
- `output/` contains one folder per task type (e.g., `S360_FIPS/`, `S360_SecurityPack/`).
- Each task folder includes a `Workflow.md` that explains the standard operating procedure.
- After every execution, store the outcome in a new file named `yyyyMMddfff.md` (`fff` = milliseconds) within the corresponding task folder.

## Working Notes
- Keep workflow guides concise and update them when the playbook changes.
- Treat timestamped run logs as immutable records; create a new file for addenda or reruns.
