// =====================================================================
// AzureOps — Azure Functions Module
// Deploys a Storage Account and hosts the Linux Function App on
// the shared App Service Plan, reading secrets via Key Vault reference.
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

@description('Key Vault name holding the SQL admin password secret')
param keyVaultName string

@description('Application Insights connection string (optional)')
param appInsightsConnectionString string = ''

@description('Resource ID of the existing App Service Plan')
param appServicePlanId string

var storageAccountName = 'stazureops${environment}'
var functionAppName = 'func-azureops-${environment}'

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
    httpsOnly: true
    keyVaultReferenceIdentity: 'SystemAssigned'
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
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/sql-admin-password/)'
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
output functionAppPrincipalId string = functionApp.identity.principalId
output storageAccountName string = storageAccount.name
