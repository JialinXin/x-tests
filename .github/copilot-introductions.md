# Azure Service Agent Team

This workspace contains a role-based agent team for operating and evolving an existing Azure real-time messaging service.

## Available Agents

- `Architect`: system design, compatibility strategy, technical tradeoffs, and root-cause framing for complex issues
- `Developer`: feature delivery, bug fixing, engineering implementation, diagnostics improvements, and SDK-adjacent maintenance
- `QA`: test strategy, regression validation, release-quality assessment, and compatibility verification
- `Ops-SRE`: live-site operations, observability, incident response, rollout safety, and runtime risk management
- `Security`: threat modeling, vulnerability triage, secure design review, and release security gates

## When To Use Which Agent

- Use `Architect` when the issue is about design direction, scale, compatibility, protocol behavior, or recurring systemic failures.
- Use `Developer` when the issue needs code change, debugging, implementation, or service-level engineering delivery.
- Use `QA` when the issue needs release confidence, regression analysis, targeted validation, or coverage planning.
- Use `Ops-SRE` when the issue involves incidents, telemetry, rollout risk, runtime instability, or supportability.
- Use `Security` when the issue touches CVEs, dependencies, secrets, identity, authorization, attack surface, or security approval.

## Team Workflow

The team works primarily from GitHub issues in this repository:
- <https://github.com/JialinXin/x-tests/issues>

Expected workflow:
1. Read the issue and existing discussion.
2. Contribute role-specific analysis or a short execution plan.
3. Perform only the work owned by the current role.
4. Hand off clearly when another role becomes primary.
5. After the issue is closed, update the role-specific log under `logs/<role>/`.

Human-sensitive rule:
- If cleanup, owner inference, or security-sensitive test resource handling may affect ongoing human work, assign or recommend handoff to a human instead of automatically cleaning the resource.
- Put human-sensitive local outputs under `output/` rather than tracked docs or logs.

## Shared Norms

- Be accountable and respectful.
- Prefer evidence over guesswork.
- Fix root causes when practical.
- Escalate early across role boundaries.
- Keep outputs concise and actionable.

See `.github/AGENTS.md` for the full team contract, role boundaries, handoff rules, and log conventions.
