# Bootstrap Checklist (OIDC + Secrets + SSH)

Use this checklist to prepare and run the **Bootstrap OIDC and Repo Settings** workflow with maximum automation.

## Goal

Complete all of the following in one workflow run:

1. Create Entra App Registration + service principal
2. Configure federated credentials for GitHub Actions
3. Assign required Azure roles at subscription scope
4. Set GitHub repository variables for Azure login
5. Set GitHub repository secrets for Telegram and SSH
6. Auto-generate SSH key pair (optional) and store private key secret

## Pre-Run Requirements

1. Repository contains workflow file: `.github/workflows/bootstrap-oidc.yml`
2. You have GitHub admin/maintainer rights for repository variables and secrets
3. You have Azure rights to create app registrations and role assignments
4. Repository secret `AZURE_BOOTSTRAP_CREDENTIALS` is set (unless you pass credentials via workflow input)
5. Telegram bot token is ready

## Bootstrap Credentials Format

`AZURE_BOOTSTRAP_CREDENTIALS` should match the standard `azure/login` JSON shape:

```json
{
  "clientId": "<app-client-id>",
  "clientSecret": "<app-client-secret>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>"
}
```

## Recommended Workflow Inputs

Run **Bootstrap OIDC and Repo Settings** with these values:

1. `app_name`: `openclaw-github-actions` (or your preferred name)
2. `azure_bootstrap_credentials`: empty (use repo secret)
3. `target_tenant_id`: your tenant ID
4. `target_subscription_id`: your subscription ID
5. `generate_ssh_key`: `true`
6. `ssh_public_key`: empty
7. `ssh_private_key_secret_name`: `OPENCLAW_SSH_PRIVATE_KEY`
8. `telegram_bot_token`: your token

## What the Workflow Sets

### Repository Variables

1. `AZURE_CLIENT_ID`
2. `AZURE_TENANT_ID`
3. `AZURE_SUBSCRIPTION_ID`

### Repository Secrets

1. `SSH_PUBLIC_KEY`
2. `TELEGRAM_BOT_TOKEN`
3. `OPENCLAW_SSH_PRIVATE_KEY` (only when key generation is enabled and public key input is empty)

## Post-Run Validation

After workflow is green, verify:

1. Variables exist in **Settings -> Secrets and variables -> Actions -> Variables**
2. Secrets exist in **Settings -> Secrets and variables -> Actions -> Secrets**
3. Workflow summary includes:
   - app registration ID
   - tenant and subscription IDs
   - SSH key source (`provided` or `generated`)

## Deploy Sequence After Bootstrap

1. Ensure GitHub environment `prod` exists and required reviewers are configured
2. Run workflow: `Deploy Infrastructure`
3. Approve `prod` environment gate
4. Run local validation:

```bash
./scripts/validate-deployment.sh
```

## Access Model Recommendation

1. Primary access: Azure AD SSH (recommended)
2. Fallback access: key-based SSH using `OPENCLAW_SSH_PRIVATE_KEY`

## Failure Recovery Tips

1. Tenant mismatch error: update bootstrap credentials or `target_tenant_id`
2. Subscription mismatch error: verify `target_subscription_id`
3. Role assignment failures: check permissions of bootstrap identity
4. Duplicate app name concerns: use a unique `app_name` input
