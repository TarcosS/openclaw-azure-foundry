using '../main.bicep'

param location = 'eastus2'
param resourceGroupName = 'rg-openclaw'
param vnetName = 'vnet-openclaw'
param vmName = 'vm-openclaw'
param vmSize = 'Standard_B2as_v2'
param osDiskSizeGb = 64
param adminUsername = 'openclaw'
param aiFoundryAccountName = 'oc-foundry-eus2'
param modelName = 'gpt-5.4-mini'
param modelVersion = '2026-03-17'
param modelCapacity = 30
param keyVaultName = 'kv-oc-eus2'
// sshPublicKey and telegramBotToken passed at deploy time via CLI or GitHub Actions
