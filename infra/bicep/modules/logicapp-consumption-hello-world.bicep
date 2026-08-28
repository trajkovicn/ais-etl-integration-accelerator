@description('Logic App (Consumption) name.')
param logicAppName string

@description('Azure region for deployment (e.g., eastus, westus2).')
param location string

@description('Storage account name used for the XML/audit store.')
param storageAccountName string

@secure()
@description('Storage account access key.')
param storageAccountAccessKey string

@description('Blob container used for the XML/audit store.')
param blobContainerName string = 'xml-store'

@secure()
@description('Service Bus namespace connection string.')
param serviceBusConnectionString string

@description('Service Bus queue name that receives messages.')
param serviceBusQueueName string = 'inbound'

@description('Azure Blob API connection resource name.')
param azureBlobConnectionName string = 'azureblob'

@description('Service Bus API connection resource name.')
param serviceBusConnectionName string = 'servicebus'

var azureBlobManagedApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
var serviceBusManagedApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')

resource azureBlobConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: azureBlobConnectionName
  location: location
  properties: {
    displayName: azureBlobConnectionName
    api: {
      id: azureBlobManagedApiId
    }
    parameterValues: {
      accountName: storageAccountName
      accessKey: storageAccountAccessKey
    }
  }
}

resource serviceBusConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: serviceBusConnectionName
  location: location
  properties: {
    displayName: serviceBusConnectionName
    api: {
      id: serviceBusManagedApiId
    }
    parameterValues: {
      connectionString: serviceBusConnectionString
    }
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          type: 'Object'
          defaultValue: {}
        }
      }
      triggers: {
        When_a_HTTP_request_is_received: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
          }
        }
      }
      actions: {
        CorrelationId: {
          type: 'Compose'
          inputs: '@{guid()}'
        }
        Ensure_XML_ContentType: {
          type: 'If'
          runAfter: {
            CorrelationId: [
              'Succeeded'
            ]
          }
          expression: {
            or: [
              {
                contains: [
                  '@{toLower(coalesce(triggerOutputs()?[\'headers\']?[\'Content-Type\'], \'\'))}'
                  'application/xml'
                ]
              }
              {
                contains: [
                  '@{toLower(coalesce(triggerOutputs()?[\'headers\']?[\'Content-Type\'], \'\'))}'
                  'text/xml'
                ]
              }
            ]
          }
          actions: {
            Write_request_to_ADLS_Gen2_as_blob: {
              type: 'ApiConnection'
              inputs: {
                body: '@{triggerBody()}'
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/datasets/default/files'
                queries: {
                  folderPath: '@{concat(\'/\', encodeURIComponent(\'${blobContainerName}\'))}'
                  name: '@{concat(\'message-\', outputs(\'CorrelationId\'), \'.xml\')}'
                  queryParametersSingleEncoded: true
                }
                runtimeConfiguration: {
                  contentTransfer: {
                    transferMode: 'Chunked'
                  }
                }
              }
            }
            Send_message_to_ServiceBus_queue: {
              type: 'ApiConnection'
              runAfter: {
                Write_request_to_ADLS_Gen2_as_blob: [
                  'Succeeded'
                ]
              }
              inputs: {
                body: {
                  ContentData: '@{encodeBase64(triggerBody())}'
                  CorrelationId: '@{outputs(\'CorrelationId\')}'
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/@{encodeURIComponent(\'${serviceBusQueueName}\')}/messages'
              }
            }
            Response_OK: {
              type: 'Response'
              runAfter: {
                Send_message_to_ServiceBus_queue: [
                  'Succeeded'
                ]
              }
              inputs: {
                statusCode: 200
                body: {
                  message: 'Hello from the Azure Integration Modernization Accelerator'
                  correlationId: '@{outputs(\'CorrelationId\')}'
                  storedIn: blobContainerName
                  queuedTo: serviceBusQueueName
                }
              }
            }
          }
          else: {
            actions: {
              Response_Unsupported_Media_Type: {
                type: 'Response'
                inputs: {
                  statusCode: 415
                  body: {
                    message: 'Unsupported Media Type. Send XML with Content-Type application/xml or text/xml.'
                    correlationId: '@{outputs(\'CorrelationId\')}'
                  }
                }
              }
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: azureBlobConnection.id
            connectionName: azureBlobConnection.name
            id: azureBlobManagedApiId
          }
          servicebus: {
            connectionId: serviceBusConnection.id
            connectionName: serviceBusConnection.name
            id: serviceBusManagedApiId
          }
        }
      }
    }
  }
}

output logicAppId string = logicApp.id
