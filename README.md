# openclaw-azure-foundry

Deploy a private [OpenClaw](https://openclaw.ai) AI assistant on Azure, connect it to Telegram, and manage it with GitHub Actions CI/CD using OIDC authentication — no stored cloud credentials.

This project is designed for teams that need strong security controls and repeatable deployment while still giving developers a fast path to adoption.

## Architecture

[![Architecture Diagram](https://app.eraser.io/workspace/FxqFVv3guQinjSs8UiS6/preview?elements=OrdqoAHBlks39KuU5JUbI&type=embed)](https://app.eraser.io/workspace/FxqFVv3guQinjSs8UiS6)

### Data Flow

1. **User → Telegram → VM**: Messages flow from Telegram to the OpenClaw gateway on a private Azure VM via long polling.
2. **VM → Azure AI Services**: OpenClaw calls GPT-4o via the OpenAI Responses API through a private endpoint.
3. **VM → Key Vault**: The VM's managed identity reads secrets (API key, bot token) through a private endpoint.
4. **CI/CD → Azure**: GitHub Actions authenticates via OIDC federation with Entra ID — no stored service principal secrets.

### Security Highlights

- VM has no public IP; NSG denies inbound from internet.
- Azure AI Services and Key Vault have public access disabled (private endpoints only).
- VM uses managed identity to retrieve secrets from Key Vault.
- GitHub Actions authenticates with OIDC federation, not client secrets.
- Telegram uses pairing mode — only approved senders can interact with the bot.

## Who This Is For

This repository is a good fit if you need:

1. No public VM endpoint.
2. No long-lived cloud credentials in GitHub.
3. Private AI and Key Vault connectivity over private endpoints.
4. A deployment path that is understandable, auditable, and easy to demo.

## What This Project Deploys

One deployment creates:

1. A resource group.
2. A virtual network with a private VM subnet and private endpoint subnet.
3. An Azure AI Services account with a GPT-4o model deployment.
4. Azure AI Foundry Hub and Project resources.
5. A private Key Vault with secrets (API key, Telegram bot token).
6. A Linux VM with OpenClaw installed and managed by systemd.
7. Private endpoints and private DNS zone links for AI Services and Key Vault.

## Repository Layout

| Path | Description |
|------|-------------|
| [infrastructure/main.bicep](infrastructure/main.bicep) | Root subscription-scope Bicep deployment |
| [infrastructure/modules/](infrastructure/modules) | Networking, compute, AI services, Key Vault, private endpoints |
| [infrastructure/parameters/](infrastructure/parameters) | Environment parameter files (`prod.bicepparam`) |
| [infrastructure/cloud-init/](infrastructure/cloud-init) | VM bootstrap: installs Node.js, Azure CLI, OpenClaw; creates systemd service |
| [openclaw-config/](openclaw-config) | Runtime OpenClaw config templates (`openclaw.template.json`, `auth-profiles.template.json`) |
| [.github/workflows/](.github/workflows) | CI/CD pipelines (bootstrap, validate, deploy, config, pairing) |
| [scripts/](scripts) | Operational helpers: connect, validate, teardown |
| [cli/](cli) | Local CLI tool for workshop/demo deployments |
| [docs/](docs) | Setup, architecture, and troubleshooting documentation |

## CI/CD Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [bootstrap-oidc.yml](.github/workflows/bootstrap-oidc.yml) | `workflow_dispatch` | One-time setup: creates Entra app registration, service principal, federated credentials, Azure role assignments, and sets repo variables/secrets |
| [validate.yml](.github/workflows/validate.yml) | Pull requests | Bicep compile/lint, ARM validation, shell script linting |
| [infra-deploy.yml](.github/workflows/infra-deploy.yml) | Push to `main` (infra changes) | What-if preview → `prod` environment approval → Bicep deployment → VM verification |
| [openclaw-config.yml](.github/workflows/openclaw-config.yml) | Push to `main` (config changes) | Renders config templates, fetches secrets on VM via managed identity, restarts OpenClaw |
| [approve-pairing.yml](.github/workflows/approve-pairing.yml) | `workflow_dispatch` | Approves Telegram pairing codes for new users via `az vm run-command` |

## Prerequisites

1. Azure subscription with subscription-scope deployment permissions.
2. GitHub repository with Actions enabled.
3. Azure CLI installed and logged in.
4. Telegram bot token from [@BotFather](https://t.me/BotFather).
5. SSH keypair for VM access.
6. A GitHub classic PAT with `repo` scope (stored as `BOOTSTRAP_GH_PAT` secret for the bootstrap workflow).

### Tooling Quick Checks

```bash
az --version
az account show -o table
gh auth status
```

SSH key generation:

```bash
ssh-keygen -t ed25519 -C "openclaw"
```

## End-to-End Setup

Follow these steps in order for a first successful deployment.

### Step 1: Fork or Clone

```bash
git clone https://github.com/hkaanturgut/openclaw-azure-foundry.git
cd openclaw-azure-foundry
```

### Step 2: Create Bootstrap PAT

1. Create a GitHub classic PAT with `repo` scope.
2. Store it as a repository secret named `BOOTSTRAP_GH_PAT`.

### Step 3: Run Bootstrap Workflow

Go to **Actions → Bootstrap OIDC & Repo Settings → Run workflow**.

This automatically:
1. Creates an Entra ID app registration and service principal.
2. Adds federated credentials for `main`, `pull_request`, and `environment:prod` subjects.
3. Assigns `Contributor` and `User Access Administrator` roles on your subscription.
4. Sets repository variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) and secrets (`SSH_PUBLIC_KEY`, `TELEGRAM_BOT_TOKEN`).

### Step 4: Create GitHub Environment

1. Create a `prod` environment in **Settings → Environments**.
2. Add required reviewers for deployment approval gates.

> **Note**: Environment protection rules require a public repository or GitHub Team/Enterprise plan.

### Step 5: Review Parameters

Check [infrastructure/parameters/prod.bicepparam](infrastructure/parameters/prod.bicepparam):

1. Resource names are globally unique where required.
2. Region and VM size fit your needs.
3. Model and capacity settings are appropriate.

### Step 6: Push to Main

```bash
git push origin main
```

This triggers the infrastructure deployment pipeline: **what-if → approval → deploy → verify**.

### Step 7: Push OpenClaw Config

After infrastructure deployment succeeds, trigger the config workflow:

1. Make a change in `openclaw-config/` and push to `main`, or
2. Manually trigger the `Update OpenClaw Config` workflow.

This renders config templates, fetches secrets from Key Vault on the VM, and restarts the OpenClaw gateway.

### Step 8: Approve Telegram Pairing

When you first message the bot, OpenClaw returns a pairing code. Approve it:

1. Go to **Actions → Approve Telegram Pairing → Run workflow**.
2. Enter the pairing code from the Telegram message.

### Step 9: Test the Bot

Send a message to your Telegram bot. It should respond with a GPT-4o generated reply.

## Deployment Verification

After deployment, verify in this order:

1. **Workflow status**: All CI/CD runs green.
2. **VM service health**:
   ```bash
   ./scripts/validate-deployment.sh
   ```
3. **Connect to VM** (if needed):
   ```bash
   az extension add -n ssh
   ./scripts/connect.sh
   ```
4. **Service logs**:
   ```bash
   sudo systemctl status openclaw
   sudo journalctl -u openclaw -n 100 --no-pager
   ```
5. **Telegram**: Send a message and confirm the bot responds.

## CLI Mode (Workshop/Demo)

For faster onboarding without GitHub Actions:

```bash
cd cli
npm install
npm run build
openclaw-azure init    # generates config and parameters
openclaw-azure deploy  # runs preflight checks and deploys
```

## Operational Model

- Infrastructure changes: PR → merge to `main` → automated deployment.
- Config changes: edit `openclaw-config/` → push to `main` → automated config push.
- Secret rotation: update Key Vault secrets → re-trigger config workflow.
- Never store API keys in repository files. Use Key Vault as the source of truth.

## Cost Guidance

Cost depends mostly on:

1. VM SKU and uptime.
2. Azure AI model usage and capacity.
3. Private endpoint count.

Use Azure Cost Management and set budget alerts early. For demos, use low-cost SKUs and teardown immediately after.

## Cleanup

```bash
./scripts/teardown.sh
```

or

```bash
az group delete --name rg-openclaw --yes --no-wait
```

## Common Pitfalls

| Issue | Cause |
|-------|-------|
| Deployment blocked without approval button | Missing `prod` environment or reviewers not configured |
| `HTTP 403` on bootstrap secrets step | `BOOTSTRAP_GH_PAT` missing or expired |
| `404 Resource not found` from AI model | Wrong `baseUrl` or `api` type in OpenClaw config |
| Telegram bot not responding | Pairing not approved, or OpenClaw service crashed |
| Federated credential "duplicate values" error | Entra ID eventual consistency — retry after a few seconds |

## Additional Documentation

- [docs/SETUP.md](docs/SETUP.md): Detailed command-level setup.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): Deep architectural rationale.
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md): Failure patterns and fixes.
- [docs/BOOTSTRAP-CHECKLIST.md](docs/BOOTSTRAP-CHECKLIST.md): Bootstrap automation checklist.

## FAQ

### Do I have to use GitHub CI/CD?

No. You can use CLI mode (`openclaw-azure init` + `openclaw-azure deploy`) for faster setup, especially for demos and workshops.

### Is the VM publicly exposed?

No. The VM has no public IP and is only accessible through Azure tools (`az vm run-command`, `az ssh vm`).

### Where are secrets stored?

In Azure Key Vault. The VM retrieves secrets at runtime through its managed identity via private endpoint.

### Can I customize the AI model?

Yes. Adjust model fields in the parameter file and rerun the deployment.

## Contributing

Contributions are welcome. Please open an issue first for significant changes and ensure workflows pass before submitting a pull request.

## License

MIT. See [LICENSE](LICENSE).
