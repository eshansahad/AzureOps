// =====================================================================
// AzureOps — App Service Module
// Deploys a Linux App Service Plan (Free tier) + Web App running
// Node.js, with a system-assigned managed identity for future
// Key Vault / SQL access without stored credentials.
// =====================================================================

@description('Environment name (dev, test, stage, prod)')
param environment string

@description('Azure region for the App Service')
param location string

@description('Node.js runtime version')
param nodeVersion string = '22-lts'

@description('SQL Server fully qualified domain name')
param dbServerFqdn string

@description('SQL Database name')
param dbDatabaseName string

@description('SQL admin login (used by the app to connect)')
param dbAdminLogin string

@secure()
@description('SQL admin password (used by the app to connect)')
param dbAdminPassword string

@description('Application Insights connection string (optional; set manually after first Application Insights setup)')
param appInsightsConnectionString string = ''

var appServicePlanName = 'asp-azureops-${environment}'
var appServiceName = 'app-azureops-${environment}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  properties: {
    reserved: true // required for Linux
  }
}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
      appCommandLine: 'npm start'
      alwaysOn: false // not available on Free tier
      appSettings: [
        {
          name: 'DB_SERVER'
          value: dbServerFqdn
        }
        {
          name: 'DB_DATABASE'
          value: dbDatabaseName
        }
        {
          name: 'DB_USER'
          value: dbAdminLogin
        }
        {
          name: 'DB_PASSWORD'
          value: dbAdminPassword
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

output appServiceName string = appService.name
output appServiceDefaultHostname string = appService.properties.defaultHostName
output appServicePrincipalId string = appService.identity.principalId
output appServicePlanId string = appServicePlan.id
