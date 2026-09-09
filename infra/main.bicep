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

@description('SQL Server administrator login')
param sqlAdminLogin string = 'eshan'

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('Your public IP address, allowed through the SQL firewall for management access')
param clientIpAddress string

var namePrefix = 'azureops'
var resourceGroupName = 'rg-${namePrefix}-${environment}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Project: 'AzureOps'
    Environment: environment
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
    location: location
  }
}

output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output sqlDatabaseName string = sql.outputs.sqlDatabaseName
output appServiceHostname string = appService.outputs.appServiceDefaultHostname
