using '../main.bicep'

param location = 'eastus2'
param resourceGroupName = 'rg-openclaw-dev'
param vnetName = 'vnet-openclaw-dev'
param vmName = 'vm-openclaw-dev'
param vmSize = 'Standard_B2as_v2'
param osDiskSizeGb = 64
param adminUsername = 'openclaw'
param aiFoundryAccountName = 'oc-foundry-dev-eus2'
param modelName = 'gpt-5.4-mini'
param modelVersion = '2026-03-17'
param modelCapacity = 30
param keyVaultName = 'kv-oc-dev-eus2'
// sshPublicKey and telegramBotToken passed at deploy time via CLI or GitHub Actions
