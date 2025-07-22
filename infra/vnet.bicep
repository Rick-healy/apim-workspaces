/*
  Virtual Network deployment for API Management with gateway workspaces
  
  This template creates:
  - A virtual network 
  - Network Security Groups for the subnets
  - A subnet for the API Management instance (/27)
  - Individual subnets for each gateway workspace (/27 CIDR blocks)
  - NO subnet delegations for simplicity
*/

// Parameters
@description('The Azure region to deploy to')
param location string

@description('Virtual Network name')
param vnetName string 

@description('Virtual Network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Number of workspace subnets to create')
param workspaceCount int

@description('Resource name token for uniqueness')
param resourceToken string

// Variables
var apimSubnetName = 'snet-apim'
var appGwSubnetName = 'snet-appgw'
var apimNsgName = 'nsg-apim'
var appGwNsgName = 'nsg-appgw'
var workspaceNsgBaseName = 'nsg-workspace'

// Define subnet prefixes with /27 CIDR blocks (32 IPs each, 27 usable after Azure reserves 5)
// Adding Application Gateway subnet as well
var subnetPrefixes = [
  '10.0.0.0/27'         // APIM: 10.0.0.0/27 (10.0.0.0 - 10.0.0.31)
  '10.0.0.32/27'        // Application Gateway: 10.0.0.32/27 (10.0.0.32 - 10.0.0.63)
  '10.0.0.64/27'        // Workspace 1: 10.0.0.64/27 (10.0.0.64 - 10.0.0.95)
  '10.0.0.96/27'        // Workspace 2: 10.0.0.96/27 (10.0.0.96 - 10.0.0.127)
  '10.0.0.128/27'       // Workspace 3: 10.0.0.128/27 (10.0.0.128 - 10.0.0.159)
]

// Create NSG for the APIM subnet (Internal mode requires more restrictive rules)
resource apimNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: '${apimNsgName}-${resourceToken}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Management_Endpoint'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3443'
          description: 'Required for API Management control plane access'
        }
      }
      {
        name: 'Allow_AppGW_to_APIM'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.0.32/27' // App Gateway subnet
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow Application Gateway to access APIM'
        }
      }
      {
        name: 'Allow_LoadBalancer'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Allow Azure Load Balancer'
        }
      }
    ]
  }
}

// Create NSG for Application Gateway subnet
resource appGwNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: '${appGwNsgName}-${resourceToken}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_Internet_HTTP'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          description: 'Allow HTTP from Internet'
        }
      }
      {
        name: 'Allow_Internet_HTTPS'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow HTTPS from Internet'
        }
      }
      {
        name: 'Allow_GatewayManager'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          description: 'Required for Application Gateway management'
        }
      }
    ]
  }
}

// Create NSGs for workspace subnets
resource workspaceNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = [for i in range(0, workspaceCount): {
  name: '${workspaceNsgBaseName}-${i + 1}-${resourceToken}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_Gateway_Manager'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Required for Gateway Manager access'
        }
      }
      {
        name: 'Allow_APIM_Access'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          description: 'Allow APIM to access Gateway'
        }
      }
    ]
  }
}]

// Create Virtual Network with all subnets - NO DELEGATIONS
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: '${vnetName}-${resourceToken}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      // APIM Subnet - no delegation (Internal mode)
      {
        name: apimSubnetName
        properties: {
          addressPrefix: subnetPrefixes[0]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: apimNsg.id
          }
        }
      }
      // Application Gateway Subnet - no delegation
      {
        name: appGwSubnetName
        properties: {
          addressPrefix: subnetPrefixes[1]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: appGwNsg.id
          }
        }
      }
      // Workspace 1 Subnet - with delegation for APIM workspace gateway
      {
        name: 'snet-workspace-1'
        properties: {
          addressPrefix: subnetPrefixes[2]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: workspaceNsg[0].id
          }
          delegations: [
            {
              name: 'delegation-to-apim-workspace'
              properties: {
                serviceName: 'Microsoft.Web/hostingEnvironments'
              }
            }
          ]
        }
      }
      // Workspace 2 Subnet - no delegation
      {
        name: 'snet-workspace-2'
        properties: {
          addressPrefix: subnetPrefixes[3]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: workspaceNsg[1].id
          }
        }
      }
      // Workspace 3 Subnet - no delegation
      {
        name: 'snet-workspace-3'
        properties: {
          addressPrefix: subnetPrefixes[4]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: workspaceNsg[2].id
          }
        }
      }
    ]
  }
}

// Outputs
output vnetName string = vnet.name
output vnetId string = vnet.id
output apimSubnetId string = '${vnet.id}/subnets/${apimSubnetName}'
output appGwSubnetId string = '${vnet.id}/subnets/${appGwSubnetName}'
output workspaceSubnetIds array = [for i in range(0, workspaceCount): '${vnet.id}/subnets/snet-workspace-${i + 1}']
