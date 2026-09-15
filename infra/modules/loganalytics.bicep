// infra/modules/loganalytics.bicep
// Provisions the Log Analytics Workspace that was missing from the original
// build — Application Insights was running in classic mode, not
// workspace-based, so this closes a real gap against the proposal's
// 15-service checklist (not just a missing screenshot).

@description('Location for the Log Analytics workspace')
param location string = 'centralus'

@description('Retention in days — kept short for cost control on a dev/portfolio subscription')
param retentionInDays int = 30

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-azureops-dev'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

output workspaceId string = logAnalytics.id
