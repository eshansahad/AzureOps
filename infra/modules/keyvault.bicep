// =====================================================================
// AzureOps — Key Vault Module
// Deploys a Key Vault using the Azure RBAC permission model, and
// grants "Key Vault Secrets User" to any principal IDs passed in
// (e.g. App Service / Function App system-assigned identities) so
// they can resolve Key Vault references at runtime.
// =====================================================================

@description('Environment name (dev, test, stage, prod)')
param environment string

@description('Azure region for the Key Vault')
param location string

@description('Principal IDs (managed identities) to grant read access to secrets via RBAC')
param secretsReaderPrincipalIds array = []

var keyVaultName = 'kv-azureops-${environment}'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

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
    enablePurgeProtection: true // matches the live vault's state; this setting is irreversible once enabled
    publicNetworkAccess: 'Enabled'
    accessPolicies: []
  }
}

resource secretsUserRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in secretsReaderPrincipalIds: {
  name: guid(keyVault.id, principalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
