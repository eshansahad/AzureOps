// infra/modules/apim.bicep
@description('Location for the API Management instance')
param location string = 'eastus'

@description('Environment tag (dev, test, prod)')
param environment string = 'dev'

@description('Publisher email address')
param publisherEmail string = 'eshan@broboogygmail.com'

@description('Publisher name or organization')
param publisherName string = 'AzureOps'

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-azureops-${environment}'
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

output apimName string = apim.name
output apimGatewayUrl string = apim.properties.gatewayUrl
