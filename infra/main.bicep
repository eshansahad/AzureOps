// =====================================================================
// AzureOps — Main Infrastructure Template
// Scope: Subscription
// Orchestrates the resource group and all supporting modules.
// =====================================================================

targetScope = 'subscription'

@description('Environment name (dev, test, stage, prod)')
@allowed([
  'dev'
  'test'
  'stage'
  'prod'
])
param environment string = 'dev'

@description('Azure region for the resource group')
param location string = 'eastus'

@description('Azure region for SQL resources (may differ due to subscription quota restrictions)')
param sqlLocation string = 'westus'

@description('Azure region for App Service (may differ due to subscription quota restrictions)')
param appServiceLocation string = 'centralus'

@description('Azure region for Azure Functions resources (may differ due to subscription quota restrictions)')
param functionsLocation string = 'centralus'

@description('SQL Server administrator login')
param sqlAdminLogin string = 'eshan'

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('Your public IP address, allowed through the SQL firewall for management access')
param clientIpAddress string

@description('Application Insights connection string (copy from the Application Insights resource after first creation)')
param appInsightsConnectionString string = ''

var namePrefix = 'azureops'
var resourceGroupName = 'rg-${namePrefix}-${environment}'
var keyVaultName = 'kv-${namePrefix}-${environment}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
  }
}

module sql 'modules/sql.bicep' = {
  name: 'deploy-sql'
  scope: rg
  params: {
    environment: environment
    location: sqlLocation
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    clientIpAddress: clientIpAddress
  }
}

module appService 'modules/appservice.bicep' = {
  name: 'deploy-appservice'
  scope: rg
  params: {
    environment: environment
    location: appServiceLocation
    dbServerFqdn: sql.outputs.sqlServerFqdn
    dbDatabaseName: sql.outputs.sqlDatabaseName
    dbAdminLogin: sqlAdminLogin
    keyVaultName: keyVaultName
    appInsightsConnectionString: appInsightsConnectionString
  }
}

module functions 'modules/functions.bicep' = {
  name: 'deploy-functions'
  scope: rg
  params: {
    environment: environment
    location: functionsLocation
    dbServerFqdn: sql.outputs.sqlServerFqdn
    dbDatabaseName: sql.outputs.sqlDatabaseName
    dbAdminLogin: sqlAdminLogin
    keyVaultName: keyVaultName
    appInsightsConnectionString: appInsightsConnectionString
    appServicePlanId: appService.outputs.appServicePlanId
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  scope: rg
  params: {
    environment: environment
    location: location
  }
}

module alerts 'modules/alerts.bicep' = {
  name: 'deploy-alerts'
  scope: rg
  params: {
    functionAppName: functions.outputs.functionAppName
    appServicePlanName: 'asp-azureops-${environment}'
    cpuThreshold: 80
  }
}

module servicebus 'modules/servicebus.bicep' = {
  name: 'deploy-servicebus'
  scope: rg
  params: {
    location: location
    queueName: 'deployment-requests'
  }
}

module eventgrid 'modules/eventgrid.bicep' = {
  name: 'deploy-eventgrid'
  scope: rg
  params: {
    location: location
  }
}

module loganalytics 'modules/loganalytics.bicep' = {
  name: 'deploy-loganalytics'
  scope: rg
  params: {
    location: location
  }
}

module apim 'modules/apim.bicep' = {
  name: 'deploy-apim'
  scope: rg
  params: {
    location: location
    environment: environment
  }
}

// --- Storage Reports Module ---
module storagereports 'modules/storagereports.bicep' = {
  name: 'deploy-storagereports'
  scope: rg
  params: {
    storageAccountName: 'stazureopsdev'
    functionAppName: functions.outputs.functionAppName
  }
}

// --- Container Apps & ACR Module ---
module containerapps 'modules/containerapps.bicep' = {
  name: 'deploy-containerapps'
  scope: rg
  params: {
    location: appServiceLocation // centralus
    logAnalyticsWorkspaceName: 'law-azureops-dev'
  }
}

module monitoringAccess 'modules/monitoringaccess.bicep' = {
  name: 'deploy-monitoring-access'
  scope: rg
  params: {
    appServiceName: 'app-azureops-dev'
  }
}

module appServiceEventGridAccess './modules/eventgridappaccess.bicep' = {
  name: 'appServiceEventGridAccess'
  scope: rg 
  params: {
    eventGridTopicName: 'eg-azureops-dev'
    appServicePrincipalId: appService.outputs.appServicePrincipalId // <-- Updated to match the existing output
  }
}

output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output sqlDatabaseName string = sql.outputs.sqlDatabaseName
output appServiceHostname string = appService.outputs.appServiceDefaultHostname
output functionAppHostname string = functions.outputs.functionAppDefaultHostname
output actionGroupId string = alerts.outputs.actionGroupId
output alertRuleId string = alerts.outputs.alertRuleId
output serviceBusNamespaceFqdn string = servicebus.outputs.serviceBusNamespaceFqdn
output logAnalyticsWorkspaceId string = loganalytics.outputs.workspaceId
output apimGatewayUrl string = apim.outputs.apimGatewayUrl
output reportsBlobEndpoint string = storagereports.outputs.blobEndpoint
output acrLoginServer string = containerapps.outputs.acrLoginServer
output containerAppFqdn string = containerapps.outputs.containerAppFqdn
