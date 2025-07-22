/*
  Application Gateway deployment for API Management ingress
  
  This template creates:
  - A public IP for the Application Gateway
  - An Application Gateway with WAF v2 SKU
  - Backend pool pointing to internal API Management
  - Health probe and routing rules
*/

// Parameters
@description('The Azure region to deploy to')
param location string

@description('Application Gateway name')
param appGwName string

@description('Resource name token for uniqueness')
param resourceToken string

@description('Subnet ID for the Application Gateway')
param appGwSubnetId string

@description('Internal API Management gateway URL (will be determined after APIM deployment)')
param apimGatewayUrl string = 'apim-internal.example.com'

// Create Public IP for Application Gateway
resource appGwPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: '${appGwName}-pip-${resourceToken}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${appGwName}-${resourceToken}'
    }
  }
}

// Create Application Gateway
resource appGw 'Microsoft.Network/applicationGateways@2022-07-01' = {
  name: '${appGwName}-${resourceToken}'
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: appGwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGwPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apimBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: apimGatewayUrl
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apimHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', '${appGwName}-${resourceToken}', 'apimHealthProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGwHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${appGwName}-${resourceToken}', 'appGwFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${appGwName}-${resourceToken}', 'port80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apimRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${appGwName}-${resourceToken}', 'appGwHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${appGwName}-${resourceToken}', 'apimBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${appGwName}-${resourceToken}', 'apimHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apimHealthProbe'
        properties: {
          protocol: 'Https'
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}

// Outputs
output appGwName string = appGw.name
output appGwId string = appGw.id
output publicIpAddress string = appGwPublicIp.properties.ipAddress
output publicFqdn string = appGwPublicIp.properties.dnsSettings.fqdn
