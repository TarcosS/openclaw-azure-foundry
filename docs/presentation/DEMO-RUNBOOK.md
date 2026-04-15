# Demo Runbook (DevOps First, CLI Second)

This runbook is designed for high reliability in a live 60-minute session.

## Session Split Used by This Runbook

1. 15 minutes: slides
2. 30 minutes: DevOps demo
3. 10 minutes: CLI demo
4. 5 minutes: Q&A

## Pre-Demo Preparation (T-24h to T-30m)

### Environment Readiness

1. Confirm active Azure subscription:

```bash
az account show -o table
```

2. Confirm active GitHub account:

```bash
gh auth status
```

3. Confirm repository and branch:

```bash
git status -sb
git log --oneline -n 3
```

4. Confirm local scripts are executable:

```bash
ls -l scripts/validate-deployment.sh scripts/connect.sh scripts/teardown.sh
```

### Browser Tabs to Pre-Open

1. GitHub Actions page for this repo.
2. GitHub Environments page (`prod` approval gate).
3. Azure Portal resource group view.
4. Azure Portal activity log (optional fallback screen).

### Terminal Layout

Prepare at least three terminal tabs:

1. Tab A: GitHub/workflow operations.
2. Tab B: Azure validation and VM commands.
3. Tab C: CLI commands (`openclaw-azure`).

### Safety Net

1. Keep one recent successful run available in GitHub Actions history.
2. Keep one pre-deployed environment available as fallback.
3. Keep one pre-recorded 60-90 second terminal clip as emergency fallback.

## Demo A (30 Minutes): DevOps CI/CD Backbone

## A1. Show Backbone Files (3 min)

Open and narrate:

1. [.github/workflows/validate.yml](../../.github/workflows/validate.yml)
2. [.github/workflows/infra-deploy.yml](../../.github/workflows/infra-deploy.yml)
3. [.github/workflows/openclaw-config.yml](../../.github/workflows/openclaw-config.yml)

Talking points:

1. Validate protects quality gates.
2. What-if provides safe change preview.
3. Approval gate enforces governance.
4. Verify stage checks runtime health.

## A2. Trigger Deployment (3 min)

Trigger via push or manual workflow dispatch.

Narration:

1. "We are not deploying blindly."
2. "We get plan visibility before apply."

## A3. Walk Through What-If (5 min)

Focus on:

1. Resource group scope.
2. Core resources to create/update.
3. Any expected unsupported what-if items.

Do not deep-read every line. Highlight risk checks and intent.

## A4. Approval Gate (2 min)

Show `prod` approval gate and approve.

Narration:

1. "This is where change control happens."
2. "Same technical workflow, policy-aware execution."

## A5. Deploy + Verify Stages (7 min)

Watch workflow progress and call out each stage outcome.

If deployment time is long:

1. explain expected wait,
2. pivot to architecture or troubleshooting slide,
3. return when job is green.

## A6. Runtime Validation (6 min)

Run:

```bash
./scripts/validate-deployment.sh
```

Then optionally connect and inspect:

```bash
az extension add -n ssh
az ssh vm --resource-group rg-openclaw --name vm-openclaw
sudo systemctl status openclaw
sudo journalctl -u openclaw -n 80 --no-pager
```

Expected outcome:

1. cloud-init complete,
2. service active,
3. no fatal runtime errors in recent logs.

## A7. Functional Proof (4 min)

1. Send message to Telegram bot.
2. Show response.
3. Briefly mention where to debug if response is delayed.

## Demo B (10 Minutes): CLI Acceleration Layer

## B1. Positioning (1 min)

Say explicitly:

1. "CLI does not replace architecture."
2. "CLI reduces onboarding and operator friction."

## B2. CLI Init (4 min)

Run:

```bash
openclaw-azure init
```

Show:

1. prompt-driven parameter capture,
2. generated files under `.openclaw-azure/`.

Optional quick view:

```bash
ls -la .openclaw-azure
cat .openclaw-azure/generated.bicepparam | head -n 40
```

## B3. CLI Deploy (4 min)

Run:

```bash
openclaw-azure deploy
```

Call out:

1. preflight checks,
2. runtime token prompt,
3. deployment execution parity with DevOps backbone.

## B4. Outcome Summary (1 min)

1. Same infrastructure model.
2. Same security posture.
3. Better user onboarding speed.

## Fallback Strategy (If Live Issues Happen)

## Fallback 1: GitHub Workflow Delay

1. Open a recent successful run.
2. Walk through each stage outcome.
3. Continue with live runtime validation in existing environment.

## Fallback 2: Azure CLI Timeout or Auth Issue

1. Show `az account show` to surface auth context.
2. Narrate root cause quickly.
3. Switch to pre-recorded output and continue flow.

## Fallback 3: Telegram Delay

1. Show service status and logs first.
2. Retry one message.
3. If still delayed, continue with runbook outcomes and troubleshooting path.

## Red-Flag Checklist (Keep Visible During Demo)

1. Wrong GitHub account active.
2. Wrong Azure subscription active.
3. Missing or blocked `prod` approval reviewer.
4. SSH extension missing.
5. Expired or incorrect Telegram token.

## Command Snippets (Quick Copy Block)

```bash
gh auth status
az account show -o table
./scripts/validate-deployment.sh
openclaw-azure init
openclaw-azure deploy
```

## Final 30-Second Close

"You saw the full engineering backbone first: policy-aware CI/CD, private networking, and runtime verification. Then you saw the exact same system deployed through CLI for speed. This gives teams both governance and developer velocity."
