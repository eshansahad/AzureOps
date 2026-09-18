// infra/modules/eventgridappaccess.bicep
// Extends the existing Event Grid topic to a second publisher: the App
// Service can now also publish platform events (Environment.Created,
// Environment.Decommissioned), not just the Function App. Same topic,
// same subscriber (logPlatformEvent) — genuinely shared pub/sub
// infrastructure rather than one component's private plumbing.

param eventGridTopicName string
param appServicePrincipalId string

resource eventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' existing = {
  name: eventGridTopicName
}

// EventGrid Data Sender Role ID
var eventGridDataSenderRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'd5a91429-5739-47e2-a06b-3470a27159e7')

resource appServiceEventGridRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(eventGridTopic.id, appServicePrincipalId, eventGridDataSenderRoleId)
  scope: eventGridTopic
  properties: {
    roleDefinitionId: eventGridDataSenderRoleId
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
