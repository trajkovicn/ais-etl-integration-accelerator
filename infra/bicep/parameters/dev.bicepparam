using '../main.bicep'

param ou = 'fin'
param biz = 'tax'
param app = 'intmod'
param env = 'dev'
param regionCode = 'eus'
param instance = '001'

param deployIntegrationAccount = true
param integrationAccountSku = 'Basic'

// Object ID (GUID) of a user or group to administer secrets in the Key Vault
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000'

// Virtual Network — set deployVnet = true to provision a /22 VNet with subnets
param deployVnet = false
// param vnetAddressPrefix = '10.0.0.0/22'   // default
// param deployDnsResolverSubnets = false      // set true if you need DNS Private Resolver subnets
