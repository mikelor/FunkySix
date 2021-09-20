@minLength(3)
@maxLength(8)
param projectName string = 'funkysix'

@allowed([
	'dev'
	'qa'
	'stg'
	'prod'
])
param projectEnvironment string = 'dev'

param location string = resourceGroup().location
param functionRuntime string = 'dotnet'

var storageAccountName = '${toLower(projectName)}${toLower(projectEnvironment)}${toLower(uniqueString(resourceGroup().id))}'
var storageEndpoint = '${projectName}StorageEndpoint'

var appServiceName = '${toLower(projectName)}-appsvc-${toLower(location)}-${toLower(projectEnvironment)}'

var functionAppName = '${toLower(projectName)}-${toLower(projectEnvironment)}'

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
	name: storageAccountName
	location: location
	sku: {
		name: 'Standard_LRS'
	}
	kind: 'StorageV2'
}

resource appServiceResource 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: appServiceName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
  }
}

resource functionAppResource 'Microsoft.Web/sites@2021-01-15' = {
  name: functionAppName
  kind: 'functionapp'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServiceResource.id
    httpsOnly: true
  }
}

resource functionAppAppSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  name: '${functionAppResource.name}/appsettings'
  properties:{
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'
    //APPINSIGHTS_INSTRUMENTATIONKEY: reference(resourceId('Microsoft.Insights/components', appInsightsName), '2020-02-02-preview').InstrumentationKey
    //APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${reference(resourceId('Microsoft.Insights/components', appInsightsName), '2020-02-02-preview').InstrumentationKey}'
    FUNCTIONS_WORKER_RUNTIME: functionRuntime
    FUNCTIONS_EXTENSION_VERSION: '~4'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    //'X-Authorization': '@Microsoft.KeyVault(SecretUri=${XAuthSecretResource})'
    //AppInsightsApiKey: '@Microsoft.KeyVault(SecretUri=${AppInsightsApiKeySecretResource})'
    //AppInsightsAppId: reference(resourceId('Microsoft.Insights/components', appInsightsName), '2020-02-02-preview').AppId
    'AzureWebJobs.StatsCollector.Disabled': 'true'
  }
}


output stgAccount string = storageAccountName
output stgEndpoint string = storageEndpoint
output functionAppHostName string = functionAppResource.properties.defaultHostName
output computedFunctionAppName string = functionAppName
