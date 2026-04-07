targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'eastus2'

@description('Resource group name')
param resourceGroupName string = 'rg-openclaw'

@description('Virtual network name')
param vnetName string = 'vnet-openclaw'

@description('Virtual machine name')
param vmName string = 'vm-openclaw'

@description('VM size')
param vmSize string = 'Standard_B2as_v2'

@description('OS disk size in GB')
param osDiskSizeGb int = 64

@description('Admin username for the VM')
param adminUsername string = 'openclaw'

@description('SSH public key for VM access')
@secure()
param sshPublicKey string

@description('Azure AI Foundry account name')
param aiFoundryAccountName string = 'oc-foundry-eus2'

@description('Model name to deploy')
param modelName string = 'gpt-5.4-mini'

@description('Model version')
param modelVersion string = '2026-03-17'

@description('Model capacity (TPM in thousands)')
param modelCapacity int = 30

@description('Key Vault name')
param keyVaultName string = 'kv-oc-eus2'

@description('Telegram bot token')
@secure()
param telegramBotToken string

// Create the resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

// 1. Networking
module networking 'modules/networking.bicep' = {
  name: 'networking'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    vnetName: vnetName
  }
  dependsOn: [rg]
}

// 2. AI Foundry
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    accountName: aiFoundryAccountName
    modelName: modelName
    modelVersion: modelVersion
    modelCapacity: modelCapacity
  }
  dependsOn: [networking]
}

// 3. Compute (deployed before keyvault to get the principalId)
module compute 'modules/compute.bicep' = {
  name: 'compute'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    vmName: vmName
    vmSize: vmSize
    osDiskSizeGb: osDiskSizeGb
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    vmSubnetId: networking.outputs.vmSubnetId
    keyVaultName: keyVaultName
    aiFoundryAccountName: aiFoundryAccountName
  }
  dependsOn: [networking]
}

// 4. Key Vault (after compute so we have the VM principal ID)
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    keyVaultName: keyVaultName
    foundryApiKey: aiFoundry.outputs.foundryApiKey
    telegramBotToken: telegramBotToken
    vmPrincipalId: compute.outputs.vmPrincipalId
  }
  dependsOn: [compute, aiFoundry]
}

// 5. Private Endpoints
module privateEndpoints 'modules/private-endpoints.bicep' = {
  name: 'private-endpoints'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    peSubnetId: networking.outputs.peSubnetId
    foundryAccountId: aiFoundry.outputs.foundryAccountId
    keyVaultId: keyvault.outputs.keyVaultId
    openaiPrivateDnsZoneId: networking.outputs.openaiPrivateDnsZoneId
    kvPrivateDnsZoneId: networking.outputs.kvPrivateDnsZoneId
  }
  dependsOn: [keyvault]
}

output resourceGroupName string = resourceGroupName
output vmName string = vmName
output keyVaultName string = keyvault.outputs.keyVaultName
output foundryEndpoint string = aiFoundry.outputs.foundryEndpoint
