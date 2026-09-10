// =====================================================================
// AzureOps — Azure Functions Module
// Deploys a Storage Account and hosts the Linux Function App
// on the existing B1 App Service Plan.
// =====================================================================

@description('Environment name (dev, test, stage, prod)')
param environment string

@description('Azure region for Functions resources')
param location string

@description('Existing App Service Plan ID to host the Function App')
param appServicePlanId string

@description('SQL Server fully qualified domain name (function writes incidents here)')
param dbServerFqdn string

@description('SQL Database name')
param dbDatabaseName string

@description('SQL admin login')
param dbAdminLogin string

@secure()
@description('SQL admin password')
param dbAdminPassword string

@description('Application Insights connection string (optional)')
param appInsightsConnectionString string = ''

var storageAccountName = 'stazureops${environment}'
var functionAppName = 'func-azureops-${environment}'

// Storage Account required for Azure Functions runtime state & triggers
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Linux Function App attached to the shared B1 App Service Plan
resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    reserved: true
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Node|20'
      alwaysOn: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
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

output functionAppName string = functionApp.name
output functionAppDefaultHostname string = functionApp.properties.defaultHostName
output storageAccountName string = storageAccount.name
