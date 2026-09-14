// infra/modules/servicebus.bicep
// Provisions Service Bus for reliable async messaging between operational
// workflows: the portal enqueues deployment requests, and a Service Bus
// triggered Function consumes them and writes the Deployments record,
// decoupling the user-facing write path from the database write.

@description('Location for the Service Bus namespace')
param location string = 'centralus'

@description('Name of the existing App Service (sender identity)')
param appServiceName string = 'app-azureops-dev'

@description('Name of the existing Function App (receiver identity)')
param functionAppName string = 'func-azureops-dev'

@description('Name of the deployment-requests queue')
param queueName string = 'deployment-requests'

resource appService 'Microsoft.Web/sites@2023-01-01' existing = {
  name: appServiceName
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: functionAppName
}

resource sbNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: 'sb-azureops-dev'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {}
}

resource deploymentQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: sbNamespace
  name: queueName
  properties: {
    lockDuration: 'PT1M'
    maxDeliveryCount: 5
    deadLetteringOnMessageExpiration: true
  }
}

// Built-in role IDs: Azure Service Bus Data Sender / Data Receiver
var sbDataSenderRoleId = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
var sbDataReceiverRoleId = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

resource senderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespace.id, appService.id, sbDataSenderRoleId)
  scope: sbNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', sbDataSenderRoleId)
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource receiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespace.id, functionApp.id, sbDataReceiverRoleId)
  scope: sbNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', sbDataReceiverRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output serviceBusNamespaceFqdn string = '${sbNamespace.name}.servicebus.windows.net'
output queueName string = deploymentQueue.name
