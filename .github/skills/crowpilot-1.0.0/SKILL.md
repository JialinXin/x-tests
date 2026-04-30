---
name: crowpilot-1.0.0
description: "Guide for running, configuring, and interpreting results from CrowPilot (RedAICrowpilot) — a multi-agent AI-powered code vulnerability scanning tool backed by Azure AI Foundry. Use this skill when the user asks how to run CrowPilot, scan code for vulnerabilities, set up RedAICrowpilot, use agent mode, configure expert agents, interpret scan results, fix rate limiting issues, or export findings to CSV. Also use when the user mentions 'crowpilot', 'redaicrowpilot', 'red team copilot', 'vulnerability scan', or wants to analyze source code for security issues using AI agents."
---

# CrowPilot (RedAICrowpilot) Skill

CrowPilot is a multi-agent AI-powered code and vulnerability analysis tool backed by MRT's Azure AI Foundry. It orchestrates specialized "Expert Agents" to scan source code for security vulnerabilities, with a primary focus on managed code (C#/.NET).

This skill covers two variants:
- **Client Version** — pre-installed PowerShell launcher (`Launch-RedAICrowpilot.ps1`)
- **Original Version** — build-from-source .NET application (`dotnet run`)

---

## Quick Start

### Client Version (MRT pre-installed)

```powershell
# Download the latest launcher script (if not already available)
az storage blob download --account-name crowpilotlauncer --container-name launcher --name Launch-RedAICrowpilot.ps1 --file Launch-RedAICrowpilot.ps1 --auth-mode login 

# Show all available options
D:\Tools\ClawPilot\Launch-RedAICrowpilot.ps1 --help

# Scan code under D:\Code
D:\Tools\ClawPilot\Launch-RedAICrowpilot.ps1 --rootPath D:\Code
```

Set `rootPath` to the parent directory containing all local code repositories.

### Original Version (build from source)

```bash
# 1. Clone the repo
git clone https://dev.azure.com/MSFTRedTeam/AIAL%20ILDC/_git/Crowpilot
cd .\Crowpilot\RedTeamCopilot\RedAICrowpilot\

# 2. Build
dotnet build

# 3. Run with a root path
dotnet run --rootPath C:\AgentRootPath
```

---

## Prerequisites

| Dependency | Link |
|---|---|
| Git | https://git-scm.com/install/windows |
| .NET 9.0 SDK or later | https://dotnet.microsoft.com/download/dotnet/9.0 |
| Azure CLI | https://docs.microsoft.com/cli/azure/install-azure-cli |
| Azure Foundry endpoint | See Configuration section |

**Required entitlements (MRT users):**
- MRTFoundry Instance: https://coreidentity.microsoft.com/manage/Entitlement/entitlement/crowpilotpar-dwhc
- 1ES Enterprise Visibility: https://coreidentity.microsoft.com/manage/Entitlement/entitlement/1esenterpris-omwu

---

## Configuration

CrowPilot reads Azure AI Foundry connection details from `DefaultKernelConfig.json`:

```
RedTeamCopilot/Common/DefaultKernelConfig.json
```

- **MRT users**: A shared default config is provided. Teams should provision their own Foundry endpoints to avoid rate limiting.
- **External users**: Must supply their own Azure OpenAI config, or pass `--kernelConfigPath <path>`.

Ensure the identity in use has the **"Cognitive Services OpenAI Contributor"** ARM role assigned.

---

## Interactive Scan Examples

Paste these prompts directly into the CrowPilot console:

**Broad repository scan:**
```
Scan the repository at C:\source\MyProject for common vulnerabilities
```

**Scoped to a subsystem:**
```
Analyze the authentication module in C:\source\MyProject\Auth for potential security issues related to token handling and validation
```

**Language-specific:**
```
Review all C# files in C:\source\MyProject for insecure deserialization vulnerabilities
```

**API entrypoint analysis:**
```
Find all API entrypoints in C:\source\MyProject and identify which ones handle user input without proper validation
```

---

## Agent Mode (Non-Interactive / Automation)

Agent Mode runs headlessly, writes results to a SQLite DB and exports a CSV file.

> Tip: Build a standalone executable (`dotnet publish`) instead of `dotnet run` for automation pipelines.

```bash
# Scan a local path
dotnet run --agentPath c:\source\MyProject

# Clone and scan a remote repo
dotnet run --rootPath C:\CloneReposHere --agentRepoUrl https://dev.azure.com/MSFTRedTeam/AIAL%20ILDC/_git/Crowpilot

# Scan with specific expert agents only
dotnet run --agentPath c:\source\MyProject --experts "GeneralistAgent,DeserializationAgent,RCEAgent"
```

---

## Expert Agents

Expert Agents are specialized for specific vulnerability types. They live in:

```
RedTeamCopilot/VulnDiscoveryTool/VulnExpertConfigurations/
```

You can add, edit, or remove expert configurations to tune detection coverage.

---

## Outputs & Logging

| Output | Location |
|---|---|
| Console logs | stdout |
| Debug logs | `C:\Users\[user]\.redteamcopilot\logs\` |
| CSV export | Prompt: `Export all findings to C:\Users\[user]\.redteamcopilot\vulncsv\` |
| SQLite DB | Configured in `DefaultKernelConfig.json` |

---

## Troubleshooting

### Rate Limiting
All MRT users share a single Azure Foundry endpoint. During peak hours you may see hangs or throttling errors.

**Fix:** Provision a dedicated [Azure AI Foundry instance](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/how-to/deploy-foundry-models?view=foundry&preserve-view=true) and update `DefaultKernelConfig.json`.

### Large Repository Hangs
Scanning very large codebases causes the agent to hang or hit token limits.

**Fix:** Scope the scan to a specific subfolder:
```
Scan for SSRF vulnerabilities in C:\source\MyProject\Server\api
```

Or use `--experts` flag in Agent Mode to limit which agents run.

### False Positives
CrowPilot has a known significant false positive rate. Always manually validate findings before acting on them.

---

## Limitations

- Windows only
- Benchmarks and evaluations are based on managed code (C#/.NET); results on unmanaged code are not formally benchmarked
- May not detect every vulnerability — do not rely on it for complete coverage
- The Expert Agent prompt is under active review and may not be optimal
