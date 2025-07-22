// APIM Workspace and Workspace Gateway Deployment
// This module creates:
// 1. An APIM Workspace for logical separation of APIs
// 2. A dedicated Workspace Gateway with Premium SKU injected into a VNet subnet
// 3. Configuration connection between workspace and gateway

@description('Name of the existing APIM service')
param apimServiceName string

@description('Name of the workspace to create')
param workspaceName string

@description('Display name for the workspace')
param workspaceDisplayName string

@description('Description of the workspace')
param workspaceDescription string = 'APIM workspace with dedicated VNet-injected workspace gateway'

@description('Name of the workspace gateway')
param gatewayName string

@description('Location for the gateway resource')
param location string = resourceGroup().location

@description('Subnet ID for VNet injection of the workspace gateway')
param workspaceSubnetId string

// Reference to existing APIM service
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}

// Create APIM Workspace
// This provides logical separation and independent management
resource workspace 'Microsoft.ApiManagement/service/workspaces@2024-05-01' = {
  parent: apimService
  name: workspaceName
  properties: {
    displayName: workspaceDisplayName
    description: workspaceDescription
  }
}

// Create Workspace Gateway with Premium SKU 
// Using standalone resource with preview API that supports both SKU and APIM integration
resource workspaceGateway 'Microsoft.ApiManagement/gateways@2024-06-01-preview' = {
  name: gatewayName
  location: location
  sku: {
    name: 'WorkspaceGatewayPremium'
    capacity: 1
  }
  properties: {
    virtualNetworkType: 'Internal'
    backend: {
      subnet: {
        id: workspaceSubnetId
      }
    }
  }
  dependsOn: [
    workspace
    apimService
  ]
}

// Create Configuration Connection between workspace and gateway using Bicep
// This connects the workspace to its dedicated gateway
resource gatewayConfigConnection 'Microsoft.ApiManagement/gateways/configConnections@2024-06-01-preview' = {
  parent: workspaceGateway
  name: 'default'
  properties: {
    sourceId: workspace.id
    hostnames: [
      '${apimServiceName}.azure-api.net'
    ]
  }
}

// Note: Configuration connection between workspace and gateway
// The configConnections resource type is not yet available in stable API versions
// This connection needs to be established after deployment through Azure Portal, CLI, or REST API
// The connection links the workspace to the gateway so that the gateway serves the workspace's APIs

// Outputs
output workspaceId string = workspace.id
output workspaceName string = workspace.name
output gatewayId string = workspaceGateway.id
output gatewayName string = workspaceGateway.name
output configConnectionId string = gatewayConfigConnection.id
output connectionInstructions string = 'Configuration connection created automatically: workspace "${workspaceName}" connected to gateway "${gatewayName}"'
