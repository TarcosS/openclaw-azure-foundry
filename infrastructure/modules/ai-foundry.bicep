param location string
param accountName string
param modelName string = 'gpt-5.4-mini'
param modelVersion string = '2026-03-17'
param modelCapacity int = 30

resource cognitiveServicesAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: accountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
    customSubDomainName: accountName
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: cognitiveServicesAccount
  name: modelName
  sku: {
    name: 'Standard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output foundryAccountId string = cognitiveServicesAccount.id
output foundryEndpoint string = 'https://${accountName}.openai.azure.com/openai/v1'

@secure()
output foundryApiKey string = listKeys(cognitiveServicesAccount.id, cognitiveServicesAccount.apiVersion).key1
