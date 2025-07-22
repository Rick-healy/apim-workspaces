/*
  API Management deployment for gateway workspaces
  
  This template creates:
  - An API Management service in Premium tier
  - Additional configuration for networking
*/

// Parameters
@description('The Azure region to deploy to')
param location string

@description('API Management service name')
param apimServiceName string

@description('Publisher email for API Management')
param publisherEmail string

@description('Publisher name for API Management')
param publisherName string

@description('Resource name token for uniqueness')
param resourceToken string

@description('Subnet ID for the API Management service')
param apimSubnetId string

// Create API Management Service
resource apimService 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: '${apimServiceName}-${resourceToken}'
  location: location
  sku: {
    name: 'Premium'  // Using Premium tier
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    // Configure Virtual Network integration - Internal mode for secure deployment
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
  }
  tags: {
    environment: 'production'
    purpose: 'api-management'
  }
}

// Outputs
output apimName string = apimService.name
output apimId string = apimService.id
