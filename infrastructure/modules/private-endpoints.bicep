param location string
param peSubnetId string
param foundryAccountId string
param keyVaultId string
param openaiPrivateDnsZoneId string
param kvPrivateDnsZoneId string

// Private Endpoint for Azure AI Foundry (Cognitive Services)
resource foundryPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'pe-foundry-openclaw'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-foundry'
        properties: {
          privateLinkServiceId: foundryAccountId
          groupIds: ['account']
        }
      }
    ]
  }
}

resource foundryDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: foundryPrivateEndpoint
  name: 'foundry-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-openai-azure-com'
        properties: {
          privateDnsZoneId: openaiPrivateDnsZoneId
        }
      }
    ]
  }
}

// Private Endpoint for Key Vault
resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'pe-kv-openclaw'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-kv'
        properties: {
          privateLinkServiceId: keyVaultId
          groupIds: ['vault']
        }
      }
    ]
  }
}

resource kvDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: kvPrivateEndpoint
  name: 'kv-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: kvPrivateDnsZoneId
        }
      }
    ]
  }
}

output foundryPrivateEndpointId string = foundryPrivateEndpoint.id
output kvPrivateEndpointId string = kvPrivateEndpoint.id
