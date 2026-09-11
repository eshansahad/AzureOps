// =====================================================================
// AzureOps — App Service Module
// Deploys a Linux App Service Plan (Basic B1 tier) + Web App running
// Node.js, with a system-assigned managed identity used to read
// secrets from Key Vault via Key Vault references (no plaintext
// secrets in app settings or source control).
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

@description('Key Vault name holding the SQL admin password secret')
param keyVaultName string

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
    name: 'B1'
    tier: 'Basic'
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
      alwaysOn: true // supported on B1 and above; keeps the app warm and satisfies Functions co-hosting
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
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/sql-admin-password/)'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

output appServiceName string = appService.name
output appServiceDefaultHostname string = appService.properties.defaultHostName
output appServicePrincipalId string = appService.identity.principalId
output appServicePlanId string = appServicePlan.id
