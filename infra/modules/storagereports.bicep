// infra/modules/storagereports.bicep
// Gives the existing storage account (currently only used as the Functions
// runtime dependency) a real job matching the proposal's stated purpose:
// storing reports/artifacts. Adds a blob container and grants the Function
// App managed identity write access via RBAC (no connection string).

@description('Name of the existing storage account (the one backing AzureWebJobsStorage)')
param storageAccountName string

@description('Name of the existing Function App')
param functionAppName string = 'func-azureops-dev'

@description('Name of the blob container for deployment reports')
param containerName string = 'deployment-reports'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource reportsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: functionAppName
}

// Built-in role: Storage Blob Data Contributor
var blobContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, blobContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobContributorRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output containerName string = reportsContainer.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
