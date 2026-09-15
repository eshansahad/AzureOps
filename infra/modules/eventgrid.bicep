// infra/modules/eventgrid.bicep
@description('Location for the Event Grid topic')
param location string = 'centralus'

resource egTopic 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: 'eg-azureops-dev'
  location: location
  properties: {
    inputSchema: 'EventGridSchema'
  }
}

output topicEndpoint string = egTopic.properties.endpoint
output topicName string = egTopic.name
