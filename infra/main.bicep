/*
  Main Bicep deployment file for API Management with Workspaces
  
  This template creates:
  - A virtual network with 5 subnets (all /27 CIDR)
    * 1 subnet for API Management instance (Internal mode)
    * 1 subnet for Application Gateway (public ingress)
    * 3 subnets for workspace gateways (first one will be used)
  - An API Management instance (Premium tier) with Internal VNet integration
  - An Application Gateway with WAF for public access to internal APIM
  - An APIM Workspace with dedicated gateway injected into workspace subnet 1
*/

// Parameters
@description('The Azure region to deploy to')
param location string = 'uksouth'

@description('The name of the API Management service')
param apimServiceName string = 'apim-${uniqueString(resourceGroup().id)}'

@description('Publisher email required for API Management creation')
param publisherEmail string = 'admin@contoso.com'

@description('Publisher name required for API Management creation')
param publisherName string = 'Contoso Admin'

// Virtual Network parameters
@description('Virtual Network name')
param vnetName string = 'vnet-apim'

@description('Virtual Network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Application Gateway name')
param appGwName string = 'appgw-apim'

@description('Number of workspace subnets to create (fixed at 3 for this deployment)')
param workspaceCount int = 3

// Variables
var resourceToken = uniqueString(resourceGroup().id)

// Deploy Virtual Network with subnets
module virtualNetwork 'vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    workspaceCount: workspaceCount
    resourceToken: resourceToken
  }
}

// Deploy API Management instance
module apimService 'apim.bicep' = {
  name: 'apim-deployment'
  params: {
    location: location
    apimServiceName: apimServiceName
    publisherEmail: publisherEmail
    publisherName: publisherName
    apimSubnetId: virtualNetwork.outputs.apimSubnetId
    resourceToken: resourceToken
  }
  // Dependency is already implied through the apimSubnetId parameter
}

// Deploy Application Gateway for public ingress
module appGateway 'appgw.bicep' = {
  name: 'appgw-deployment'
  params: {
    location: location
    appGwName: appGwName
    appGwSubnetId: virtualNetwork.outputs.appGwSubnetId
    resourceToken: resourceToken
    // Note: APIM gateway URL will need to be updated after APIM deployment
    apimGatewayUrl: '${apimService.outputs.apimName}.azure-api.net'
  }
}

// Deploy APIM Workspace with dedicated workspace gateway (injected into workspace subnet 1)
module workspace 'apimsworkspace.bicep' = {
  name: 'workspace-deployment'
  params: {
    location: location
    apimServiceName: apimService.outputs.apimName
    workspaceName: 'workspace-primary'
    workspaceDisplayName: 'Primary Workspace'
    workspaceDescription: 'Main workspace with dedicated VNet-injected workspace gateway'
    gatewayName: 'gateway-workspace-primary'
    workspaceSubnetId: virtualNetwork.outputs.workspaceSubnetIds[0]
  }
}

// Outputs
output apimServiceName string = apimService.outputs.apimName
output vnetName string = virtualNetwork.outputs.vnetName
output appGatewayName string = appGateway.outputs.appGwName
output publicIpAddress string = appGateway.outputs.publicIpAddress
output publicFqdn string = appGateway.outputs.publicFqdn
output workspaceName string = workspace.outputs.workspaceName
output workspaceGatewayName string = workspace.outputs.gatewayName
output connectionInstructions string = workspace.outputs.connectionInstructions
