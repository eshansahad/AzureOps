// infra/modules/monitoringaccess.bicep
// Grants the App Service's managed identity read access to Azure Monitor
// metrics and fired alerts across the resource group — needed for the
// dashboard's new Metrics and Alerts panels. Read-only, no secrets.

@description('Name of the existing App Service')
param appServiceName string = 'app-azureops-dev'

resource appService 'Microsoft.Web/sites@2023-01-01' existing = {
  name: appServiceName
}

// Built-in role: Monitoring Reader
var monitoringReaderRoleId = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'

resource monitoringReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appService.id, monitoringReaderRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringReaderRoleId)
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
