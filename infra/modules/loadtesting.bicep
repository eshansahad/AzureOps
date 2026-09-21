@description('The location for the Load Testing resource')
param location string = resourceGroup().location

@description('The name of the Load Testing resource')
param loadTestName string = 'lt-azureops-dev'

resource loadTest 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: loadTestName
  location: location
  properties: {
    description: 'Load Testing Service for AzureOps Portal'
  }
}
