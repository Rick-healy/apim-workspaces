#!/bin/bash

# Undeploy script for APIM Workspace Gateway Solution
# This removes all resources deployed by the main.bicep template
# WARNING: This will permanently delete all resources in the resource group!

# Variables
RESOURCE_GROUP="rg_apim_workspace"

# Function to confirm deletion
confirm_deletion() {
    echo "⚠️  WARNING: This will permanently delete ALL resources in resource group '$RESOURCE_GROUP'"
    echo ""
    echo "Resources to be deleted:"
    echo "  - APIM Service (apim-testcorp-*)"
    echo "  - Workspace Gateway (gateway-workspace-primary)"
    echo "  - APIM Workspace (workspace-primary)"
    echo "  - Application Gateway (appgw-apim-*)"
    echo "  - Virtual Network (vnet-apim-*)"
    echo "  - All subnets, NSGs, and associated resources"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "❌ Undeploy cancelled by user."
        exit 0
    fi
}

# Function to check if resource group exists
check_resource_group() {
    echo "Checking if resource group '$RESOURCE_GROUP' exists..."
    if ! az group show --name $RESOURCE_GROUP --output none 2>/dev/null; then
        echo "ℹ️  Resource group '$RESOURCE_GROUP' does not exist. Nothing to undeploy."
        exit 0
    fi
}

# Function to list resources before deletion
list_resources() {
    echo "📋 Current resources in '$RESOURCE_GROUP':"
    az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type}" -o table
    echo ""
}

# Function to delete workspace gateway (if it exists as standalone resource)
delete_workspace_gateway() {
    echo "🗑️  Checking for standalone workspace gateway..."
    GATEWAY_EXISTS=$(az rest --method GET --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ApiManagement/gateways/gateway-workspace-primary?api-version=2024-06-01-preview" --query "name" -o tsv 2>/dev/null)
    
    if [ ! -z "$GATEWAY_EXISTS" ]; then
        echo "   Deleting standalone workspace gateway..."
        az rest --method DELETE --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ApiManagement/gateways/gateway-workspace-primary?api-version=2024-06-01-preview"
        echo "   ✅ Standalone workspace gateway deleted"
    else
        echo "   ℹ️  No standalone workspace gateway found"
    fi
}

# Function to delete resource group
delete_resource_group() {
    echo "🗑️  Deleting resource group '$RESOURCE_GROUP'..."
    echo "   This may take several minutes..."
    
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Resource group deletion initiated"
        echo ""
        echo "🔄 Deletion is running in the background..."
        echo "   You can check progress with: az group show --name $RESOURCE_GROUP"
        echo "   Or monitor in Azure Portal"
    else
        echo "   ❌ Failed to initiate resource group deletion"
        exit 1
    fi
}

# Main execution
echo "🧹 APIM Workspace Gateway Undeploy Script"
echo "=========================================="
echo ""

# Step 1: Check if resource group exists
check_resource_group

# Step 2: List current resources
list_resources

# Step 3: Confirm deletion
confirm_deletion

# Step 4: Delete standalone workspace gateway first (if exists)
delete_workspace_gateway

# Step 5: Delete the entire resource group
delete_resource_group

echo ""
echo "🎯 Undeploy Summary:"
echo "   - Resource group deletion initiated: $RESOURCE_GROUP"
echo "   - All resources will be permanently removed"
echo "   - Check Azure Portal or CLI for completion status"
echo ""
echo "ℹ️  Note: Resource group deletion may take 15-30 minutes to complete"
echo "   especially for APIM services which have longer deletion times."
