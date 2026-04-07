# Troubleshooting

Common issues and their solutions when deploying or operating `openclaw-azure-foundry`.

---

## 1. 401 Incorrect API Key

**Symptom:** OpenClaw returns a `401 Unauthorized` or "Incorrect API key provided" error.

**Cause:** OpenClaw is hitting the public OpenAI API (`api.openai.com`) instead of your Azure AI Foundry endpoint.

**Fix:** Check `openclaw.json` on the VM and ensure the `baseUrl` is set correctly:

```bash
# SSH into the VM
az ssh vm --resource-group rg-openclaw --name vm-openclaw

# Check the config
cat ~/.openclaw/openclaw.json | grep baseUrl
# Should show: "baseUrl": "https://oc-foundry-eus2.openai.azure.com/openai/v1"
```

If missing or wrong, update the file and restart:

```bash
sudo systemctl restart openclaw
```

---

## 2. No API Key Found for Provider

**Symptom:** OpenClaw logs show "No API key found for provider `azure-openai-responses`".

**Cause:** The `auth-profiles.json` file is missing or not in the correct location.

**Fix:** Verify the file exists:

```bash
ls -la ~/.openclaw/agents/main/agent/auth-profiles.json
cat ~/.openclaw/agents/main/agent/auth-profiles.json
```

The file should contain the `azure-openai-responses:default` profile with the `foundry-api-key` value. If missing, re-run the Key Vault secret retrieval and recreate it:

```bash
FOUNDRY_API_KEY=$(az keyvault secret show --vault-name kv-oc-eus2 --name foundry-api-key --query value -o tsv)
# Then recreate auth-profiles.json as documented in cloud-init.yaml
```

---

## 3. LLM Request Rejected: Credit Balance Too Low

**Symptom:** Error: "Your credit balance is too low to use the Anthropic API."

**Cause:** OpenClaw is routing requests to the Anthropic provider (Claude) instead of Azure AI Foundry.

**Fix:** Check the `model` setting in `openclaw.json`. The primary model must be `azure-openai-responses/gpt-5.4-mini`:

```json
"model": { "primary": "azure-openai-responses/gpt-5.4-mini" }
```

Also verify no `ANTHROPIC_API_KEY` environment variable is set that might be triggering auto-selection:

```bash
env | grep ANTHROPIC
```

---

## 4. Key Vault Access Denied in Cloud-Init

**Symptom:** Cloud-init logs show repeated "Waiting for Key Vault access..." messages, or the final `az keyvault secret show` returns `(Forbidden)`.

**Cause:** Azure RBAC role assignments can take 2–5 minutes to propagate after Bicep deploys them.

**How it's handled:** The cloud-init script includes a retry loop (30 attempts × 10 seconds = 5 minutes maximum wait). This usually resolves on its own.

**If it persists:**

```bash
# Check cloud-init logs on the VM
cat /var/log/cloud-init-output.log | grep -A5 "Key Vault"

# Verify the role assignment exists
az role assignment list \
  --scope $(az keyvault show --name kv-oc-eus2 --query id -o tsv) \
  --query "[?principalType=='ServicePrincipal']"
```

If the role assignment is missing, the Bicep deployment may have partially failed. Re-deploy or manually add the role.

---

## 5. Private Endpoint DNS Not Resolving

**Symptom:** `nslookup oc-foundry-eus2.openai.azure.com` returns a public IP (e.g. `20.x.x.x`) instead of a private IP (`10.40.3.x`).

**Cause:** The Private DNS Zone is not linked to the VNet, or the link was not created.

**Fix:**

```bash
# Check VNet links for the OpenAI DNS zone
az network private-dns link vnet list \
  --resource-group rg-openclaw \
  --zone-name privatelink.openai.azure.com

# Run nslookup from the VM (should resolve to 10.40.3.x)
az vm run-command invoke \
  --resource-group rg-openclaw \
  --name vm-openclaw \
  --command-id RunShellScript \
  --scripts "nslookup oc-foundry-eus2.openai.azure.com"
```

If the link is missing, re-run the Bicep deployment — the `networking` module will recreate it.

---

## 6. Telegram Bot Not Responding

**Symptom:** Messages sent to the Telegram bot receive no reply.

**Diagnosis steps:**

```bash
# SSH into the VM
az ssh vm --resource-group rg-openclaw --name vm-openclaw

# Check if the service is running
systemctl status openclaw

# Check service logs
journalctl -u openclaw -n 50 --no-pager

# Follow logs in real time
openclaw logs --follow
```

**Common causes:**

- **Service not running**: `sudo systemctl start openclaw`
- **Wrong bot token**: Check `botToken` in `~/.openclaw/openclaw.json`
- **NSG blocking outbound**: Verify outbound rules allow HTTPS (port 443) to `api.telegram.org`. The default Azure outbound rules allow all outbound — only check if you've added custom deny rules.
- **Pairing not completed**: The first message to the bot must go through the pairing flow. Send `/start` and follow the instructions.

---

## 7. `az ssh vm` Fails

**Symptom:** `az ssh vm` returns an error about missing extension or authentication.

**Fix:**

```bash
# Install the SSH extension
az extension add -n ssh

# If already installed, update it
az extension update -n ssh

# Verify your account has the correct role on the VM
az role assignment list \
  --assignee $(az account show --query user.name -o tsv) \
  --scope $(az vm show --resource-group rg-openclaw --name vm-openclaw --query id -o tsv)
# Look for: Virtual Machine User Login or Virtual Machine Administrator Login
```

If the role is missing, assign it:

```bash
az role assignment create \
  --assignee YOUR_AAD_USER_OR_GROUP \
  --role "Virtual Machine User Login" \
  --scope $(az vm show --resource-group rg-openclaw --name vm-openclaw --query id -o tsv)
```

---

## 8. `compat.supportsStore` Error

**Symptom:** OpenClaw throws an error about `compat.supportsStore` or store functionality.

**Cause:** The model configuration is missing the `compat` override that disables the store feature (not supported by Azure OpenAI).

**Fix:** Ensure `openclaw.json` has this in the model definition:

```json
"compat": { "supportsStore": false }
```

---

## 9. OpenClaw Install Wizard Blocking Cloud-Init

**Symptom:** Cloud-init hangs indefinitely on the OpenClaw install step. The install script is waiting for interactive input.

**Cause:** The OpenClaw installer defaults to interactive mode and prompts for configuration.

**Fix:** The `OPENCLAW_NONINTERACTIVE=1` environment variable must be set before running the install script. This is already handled in `cloud-init.yaml`:

```yaml
- OPENCLAW_NONINTERACTIVE=1 sudo -u ${ADMIN_USERNAME} -i bash -c 'curl -fsSL https://openclaw.ai/install.sh | bash'
```

If you're running the install manually (e.g. after SSH-ing in), prefix the command:

```bash
OPENCLAW_NONINTERACTIVE=1 bash -c 'curl -fsSL https://openclaw.ai/install.sh | bash'
```

---

## Viewing All Cloud-Init Logs

```bash
# Full cloud-init output log
sudo cat /var/log/cloud-init-output.log

# Cloud-init status
cloud-init status --long

# Individual module logs
sudo cat /var/log/cloud-init.log | grep -E "(ERROR|WARNING|WARN)"
```
