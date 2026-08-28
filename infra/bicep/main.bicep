targetScope = 'resourceGroup'

@description('Abbreviated organizational unit (OU), e.g., fin, hr, it.')
param ou string

@description('Abbreviated business area, e.g., tax, rev, ops.')
param biz string

@description('Workload/app abbreviation, e.g., ais, order, edi.')
param app string = 'ais'

@allowed(['dev', 'tst', 'uat', 'stg', 'prd'])
@description('Environment code (e.g., dev, tst, uat, stg, prd).')
param env string = 'dev'

@description('Region short code for naming (e.g., eus, wus2). Customer-supplied to match internal conventions.')
param regionCode string

@description('Instance number for uniqueness, e.g., 001.')
param instance string = '001'

@description('Azure deployment location (actual Azure region). Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Deploy an Integration Account for schemas/maps (XSLT/Liquid), partners, agreements, certificates.')
param deployIntegrationAccount bool = true

@description('Integration Account pricing tier.')
@allowed(['Free', 'Basic', 'Standard'])
param integrationAccountSku string = 'Basic'

@description('Object ID (GUID) of a user or group that will be granted Key Vault secret permissions (DEV convenience).')
param keyVaultAdminObjectId string

@description('Deploy a private Virtual Network with pre-defined subnets.')
param deployVnet bool = false

@description('VNet address space (CIDR). Only used when deployVnet is true.')
param vnetAddressPrefix string = '10.0.0.0/22'

@description('Deploy optional Azure DNS Private Resolver subnets inside the VNet.')
param deployDnsResolverSubnets bool = false

var baseName = toLower('${ou}-${biz}-${app}-${env}-${regionCode}-${instance}')

var vnetName = 'vnet-${baseName}'
var logicAppName = 'la-${baseName}'
var logAnalyticsName = 'log-${baseName}'
var serviceBusNamespaceName = 'sb-${baseName}'
var integrationAccountName = 'ia-${baseName}'

// Storage account naming constraints
var storageStem = take(replace(baseName, '-', ''), 18)
var storageAccountName = toLower(take('st${storageStem}${uniqueString(resourceGroup().id)}', 24))

// Key Vault naming constraints
var keyVaultStem = take(replace(baseName, '-', ''), 20)
var keyVaultName = toLower(take('kv${keyVaultStem}', 24))

module vnet 'modules/vnet.bicep' = if (deployVnet) {
  name: 'vnet'
  params: {
    name: vnetName
    location: location
    addressPrefix: vnetAddressPrefix
    deployDnsResolverSubnets: deployDnsResolverSubnets
  }
}

module log 'modules/loganalytics.bicep' = {
  name: 'loganalytics'
  params: {
    name: logAnalyticsName
    location: location
  }
}

module sb 'modules/servicebus.bicep' = {
  name: 'servicebus'
  params: {
    namespaceName: serviceBusNamespaceName
    location: location
  }
}

module st 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
  }
}

var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', storageAccountName)
var serviceBusAuthRuleId = resourceId(
  'Microsoft.ServiceBus/namespaces/authorizationRules',
  serviceBusNamespaceName,
  'logicapps-dev'
)
var storageKey = listKeys(storageAccountId, '2025-06-01').keys[0].value
var sbKeys = listKeys(serviceBusAuthRuleId, '2022-10-01-preview')
var sbConnectionString = sbKeys.primaryConnectionString

module kv 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: keyVaultName
    location: location
    tenantId: subscription().tenantId
    adminObjectId: keyVaultAdminObjectId
  }
}

resource sbConnSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: '${keyVaultName}/servicebus-connectionstring'
  properties: {
    value: sbConnectionString
  }
  dependsOn: [
    kv
    sb
  ]
}

resource storageKeySecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: '${keyVaultName}/storage-account-key'
  properties: {
    value: storageKey
  }
  dependsOn: [
    kv
    st
  ]
}

resource storageNameSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: '${keyVaultName}/storage-account-name'
  properties: {
    value: storageAccountName
  }
  dependsOn: [kv]
}

module ia 'modules/integration-account.bicep' = if (deployIntegrationAccount) {
  name: 'integrationAccount'
  params: {
    name: integrationAccountName
    location: location
    skuName: integrationAccountSku
  }
}

module hello 'modules/logicapp-consumption-hello-world.bicep' = {
  name: 'helloWorld'
  params: {
    logicAppName: logicAppName
    location: location
    storageAccountName: storageAccountName
    storageAccountAccessKey: storageKey
    blobContainerName: 'xml-store'
    serviceBusConnectionString: sbConnectionString
    serviceBusQueueName: 'inbound'
  }
  dependsOn: [
    sb
    st
  ]
}

// ── Private Endpoints (only when VNet is deployed) ───────────
module privateEndpoints 'modules/private-endpoints.bicep' = if (deployVnet) {
  name: 'privateEndpoints'
  params: {
    location: location
    privateEndpointsSubnetId: vnet.outputs.privateEndpointsSubnetId
    vnetId: vnet.outputs.id
    vnetName: vnetName
    storageAccountId: st.outputs.id
    storageAccountName: storageAccountName
    keyVaultId: kv.outputs.id
    keyVaultName: keyVaultName
  }
  dependsOn: [
    vnet
    sb
    st
    kv
  ]
}

output deployedNames object = {
  keyVault: keyVaultName
  logicApp: logicAppName
  logAnalytics: logAnalyticsName
  serviceBusNamespace: serviceBusNamespaceName
  storageAccount: storageAccountName
  integrationAccount: deployIntegrationAccount ? integrationAccountName : ''
  vnet: deployVnet ? vnetName : ''
}
