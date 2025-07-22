#!/bin/bash

# Complete APIM Workspace Gateway Deployment Script
# This deploys the complete solution including:
# - VNet with subnets and NSGs
# - APIM service with Internal VNet mode
# - Application Gateway for public access
# - APIM Workspace with dedicated VNet-injected gateway
# - Automatic configuration connection between workspace and gateway

# Variables
RESOURCE_GROUP="rg_apim_workspace"
LOCATION="uksouth"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="main.parameters.json"

# Create resource group if it doesn't exist
echo "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Register required resource providers
echo "Registering required resource providers..."
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.Network

# Deploy the complete Bicep template
echo "Deploying complete APIM workspace solution..."
echo "This includes:"
echo "  - Virtual Network with delegated subnets"
echo "  - APIM service (Internal VNet mode)"
echo "  - Application Gateway (public endpoint)"
echo "  - APIM Workspace (workspace-primary)"
echo "  - Workspace Gateway (WorkspaceGatewayPremium SKU)"
echo "  - Configuration Connection (automatic)"
echo ""

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file $TEMPLATE_FILE \
  --parameters @$PARAMETERS_FILE \
  --name complete-apim-workspace-$(date +%s)

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "✅ Resources deployed:"
    echo "   - VNet: vnet-apim-* with subnets"
    echo "   - APIM: apim-testcorp-* (Internal VNet mode)"
    echo "   - App Gateway: appgw-apim-* (public endpoint)"
    echo "   - Workspace: workspace-primary"
    echo "   - Gateway: gateway-workspace-primary (WorkspaceGatewayPremium)"
    echo "   - Config Connection: Automatic linking"
    echo ""
    echo "🚀 Your APIM workspace with VNet-injected gateway is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Add APIs to the workspace-primary workspace"
    echo "2. Configure API policies for workspace-specific behavior"
    echo "3. Test connectivity through the Application Gateway"
else
    echo "❌ Deployment failed. Check the error details above."
    exit 1
fi
