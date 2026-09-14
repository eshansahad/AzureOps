// infra/modules/servicebus.bicep
// Provisions Service Bus for reliable async messaging between operational
// workflows: the portal enqueues deployment requests, and a Service Bus
// triggered Function consumes them and writes the Deployments record,
// decoupling the user-facing write path from the database write.

// infra/modules/servicebus.bicep
@description('Location for the Service Bus namespace')
param location string = 'centralus'

@description('Name of the existing App Service (sender identity)')
param appServiceName string = 'app-azureops-dev'

@description('Name of the existing Function App (receiver identity)')
param functionAppName string = 'func-azureops-dev'

@description('Name of the deployment-requests queue')
param queueName string = 'deployment-requests'

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

output serviceBusNamespaceFqdn string = '${sbNamespace.name}.servicebus.windows.net'
output queueName string = deploymentQueue.name
