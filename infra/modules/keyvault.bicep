// =====================================================================
// AzureOps — Key Vault Module
// Deploys a Key Vault using the Azure RBAC permission model.
// =====================================================================

@description('Environment name (dev, test, stage, prod)')
param environment string

@description('Azure region for the Key Vault')
param location string

var keyVaultName = 'kv-azureops-${environment}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: false
    publicNetworkAccess: 'Enabled'
    accessPolicies: []
  }
}

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
