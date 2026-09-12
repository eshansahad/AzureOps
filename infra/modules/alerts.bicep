// infra/modules/alerts.bicep
// Wires a genuine event-driven trigger: an Azure Monitor metric alert on the
// shared App Service Plan's CPU automatically invokes the `remediate` Function,
// completing the detect -> remediate -> record architecture without manual
// HTTP invocation.

@description('Name of the existing Function App to notify on alert')
param functionAppName string = 'func-azureops-dev'

@description('Name of the existing shared App Service Plan being monitored')
param appServicePlanName string = 'asp-azureops-dev'

@description('Name of the HTTP-triggered function to invoke for remediation')
param remediateFunctionName string = 'remediate'

@description('CPU percentage threshold that triggers the alert')
param cpuThreshold int = 80

resource functionApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: functionAppName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' existing = {
  name: appServicePlanName
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-azureops-dev'
  location: 'global'
  properties: {
    groupShortName: 'AzOpsRemed'
    enabled: true
    azureFunctionReceivers: [
      {
        name: 'InvokeRemediateFunction'
        functionAppResourceId: functionApp.id
        functionName: remediateFunctionName
        httpTriggerUrl: 'https://${functionApp.properties.defaultHostName}/api/${remediateFunctionName}'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-azureops-dev-cpu'
  location: 'global'
  properties: {
    description: 'Fires when the shared App Service Plan CPU exceeds the configured threshold; automatically invokes the remediate function via the action group.'
    severity: 2
    enabled: true
    scopes: [
      appServicePlan.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCpu'
          metricName: 'CpuPercentage'
          metricNamespace: 'Microsoft.Web/serverfarms'
          operator: 'GreaterThan'
          threshold: cpuThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
output alertRuleId string = cpuAlert.id
