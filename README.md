# openclaw-azure-foundry

Deploy a fully private OpenClaw AI assistant on Azure with AI Foundry, connected to Telegram — with a single `git push`.

## Architecture

```
GitHub Actions (OIDC)
        │
        ▼
Azure Subscription
        │
        └── Resource Group (rg-openclaw)
                │
                ├── VNet (10.40.0.0/16)
                │     ├── snet-vm (10.40.2.0/24)  ← NSG: no inbound from Internet
                │     │     └── VM (vm-openclaw)
                │     │           └── OpenClaw + systemd ──────────────► Telegram API
                │     │                 (managed identity)
                │     └── snet-pe (10.40.3.0/24)
                │           ├── pe-foundry-openclaw
                │           └── pe-kv-openclaw
                │
                ├── Azure AI Foundry (private, no public access)
                │     └── gpt-5.4-mini deployment
                │
                ├── Key Vault (private, RBAC)
                │     ├── secret: foundry-api-key
                │     └── secret: telegram-bot-token
                │
                └── Private DNS Zones
                      ├── privatelink.openai.azure.com → pe-foundry-openclaw
                      └── privatelink.vaultcore.azure.net → pe-kv-openclaw
```

## Prerequisites

- **Azure subscription** with Owner or (Contributor + User Access Administrator) role
- **Azure CLI** (`az`) installed locally
- **GitHub account** with Actions enabled
- **Telegram account** to interact with the bot
- **SSH key pair** (Ed25519 recommended): `ssh-keygen -t ed25519 -C "openclaw"`

## Quick Start

### 1. Fork & Clone

```bash
git clone https://github.com/YOUR_ORG/openclaw-azure-foundry.git
cd openclaw-azure-foundry
```

### 2. Set Up OIDC Federation & GitHub Secrets/Variables

Create an App Registration in Azure Entra ID and configure federated credentials for your GitHub repo (see [docs/SETUP.md](docs/SETUP.md) for full instructions).

Set the following in your GitHub repository (**Settings → Secrets and variables → Actions**):

**Secrets:**

| Name | Description |
|------|-------------|
| `SSH_PUBLIC_KEY` | Contents of your `~/.ssh/id_ed25519.pub` |
| `TELEGRAM_BOT_TOKEN` | Token from BotFather (e.g. `123456:ABC-DEF...`) |

**Variables:**

| Name | Description |
|------|-------------|
| `AZURE_CLIENT_ID` | App Registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID |

### 3. Push to Main

```bash
git push origin main
```

GitHub Actions will run a `what-if` preview, wait for your approval in the `prod` environment gate, then deploy the full stack.

## Manual Deployment

```bash
az deployment sub create \
  --location eastus2 \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters/prod.bicepparam \
  --parameters sshPublicKey="$(cat ~/.ssh/id_ed25519.pub)" \
  --parameters telegramBotToken="YOUR_BOT_TOKEN"
```

## Connecting to the VM

The VM has no public IP. Connect via Azure AD SSH:

```bash
# Install the SSH extension (one-time)
az extension add -n ssh

# Connect
./scripts/connect.sh
# or directly:
az ssh vm --resource-group rg-openclaw --name vm-openclaw
```

> **Note:** Your Azure AD account must have the `Virtual Machine User Login` role on the VM or resource group.

## Cost Estimates

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|----------------------|
| Virtual Machine | Standard_B2as_v2 (2 vCPU, 8 GB RAM) | ~$30 |
| Azure AI Foundry | Pay-per-use (gpt-5.4-mini) | Varies by usage |
| Key Vault | Standard | ~$5 |
| Private Endpoint (Foundry) | — | ~$7 |
| Private Endpoint (Key Vault) | — | ~$7 |

*Estimates are approximate and may vary by region and usage.*

## Cleanup

```bash
# Using the teardown script
./scripts/teardown.sh

# Or directly with Azure CLI
az group delete --name rg-openclaw --yes --no-wait
```

## GitHub Actions Secrets & Variables

### Secrets (Settings → Secrets and variables → Actions → Secrets)

| Name | Description |
|------|-------------|
| `SSH_PUBLIC_KEY` | SSH public key for VM access |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from BotFather |

### Variables (Settings → Secrets and variables → Actions → Variables)

| Name | Description |
|------|-------------|
| `AZURE_CLIENT_ID` | App Registration (Service Principal) client ID |
| `AZURE_TENANT_ID` | Azure Active Directory tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID to deploy into |

> The `prod` GitHub environment should have a required reviewer configured for deployment gate protection.

## Contributing

Contributions are welcome! Please open an issue to discuss your idea before submitting a pull request. Ensure your changes pass the `validate` workflow (Bicep lint + `az deployment sub validate` + shellcheck).

## License

MIT — see [LICENSE](LICENSE).
