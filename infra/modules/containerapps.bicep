// infra/modules/containerapps.bicep
// Provisions ACR and Container Apps to close out the last two services from
// the proposal's 15-service checklist. Runs the containerized portal
// alongside app-azureops-dev (not replacing it — App Service stays the
// primary, Key-Vault-integrated deployment). Reuses law-azureops-dev for
// Container Apps logging rather than creating a second workspace.

@description('Location for ACR and Container Apps')
param location string = 'centralus'

@description('Name of the existing Log Analytics workspace to send Container Apps logs to')
param logAnalyticsWorkspaceName string = 'law-azureops-dev'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'acrazureopsdev'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false // pull via managed identity, not admin credentials
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-azureops-dev'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ca-azureops-dev'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: 'system'
        }
      ]
    }
    template: {
      // Placeholder image so the first infra deploy succeeds before CI/CD
      // has pushed a real build; the pipeline updates this via
      // `az containerapp update --image` afterward.
      containers: [
        {
          name: 'azureops-portal'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 2
      }
    }
  }
}

// AcrPull role so the Container App's managed identity can pull images
// without admin credentials or a stored password.
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output acrLoginServer string = acr.properties.loginServer
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
