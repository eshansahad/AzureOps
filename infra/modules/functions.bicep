// =====================================================================
// AzureOps — Azure Functions Module
// Deploys a Storage Account (required Functions dependency) and a
// Consumption-plan Linux Function App running Node.js, used for
// event-driven automation and incident remediation workflows.
// =====================================================================

@description('Environment name (dev, test, stage, prod)')
param environment string

@description('Azure region for Functions resources')
param location string

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
var hostingPlanName = 'asp-functions-${environment}'

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

// Serverless Consumption Plan (Y1) required for Linux Function Apps
resource hostingPlan 'Microsoft.Web/serverFarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true // Mandatory for Linux hosting
  }
}

// Linux Function App
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
    serverFarmId: hostingPlan.id
    reserved: true // Mandatory for Linux hosting
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Node|20'
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
