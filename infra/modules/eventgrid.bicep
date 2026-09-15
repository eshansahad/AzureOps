// infra/modules/eventgrid.bicep
// Provisions a custom Event Grid topic for internal platform events
// (IncidentResolved, DeploymentCompleted, etc.) so components communicate
// via genuine pub/sub rather than direct calls. remediate and
// processDeployment publish to it; logPlatformEvent subscribes and logs,
// fully decoupled from either producer.

// infra/modules/eventgrid.bicep
@description('Location for the Event Grid topic')
param location string = 'centralus'

@description('Name of the existing Function App (subscriber identity)')
param functionAppName string = 'func-azureops-dev'

@description('Name of the Event Grid trigger function that subscribes to platform events')
param subscriberFunctionName string = 'logPlatformEvent'

resource functionApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: functionAppName
}

resource egTopic 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: 'eg-azureops-dev'
  location: location
  properties: {
    inputSchema: 'EventGridSchema'
  }
}

resource eventSubscription 'Microsoft.EventGrid/topics/eventSubscriptions@2022-06-15' = {
  parent: egTopic
  name: 'sub-log-platform-events'
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: '${functionApp.id}/functions/${subscriberFunctionName}'
        maxEventsPerBatch: 1
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 5
      eventTimeToLiveInMinutes: 60
    }
  }
}

output topicEndpoint string = egTopic.properties.endpoint
output topicName string = egTopic.name
