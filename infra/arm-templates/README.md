# ARM Templates

This folder contains the compiled ARM templates generated from the Bicep files in the parent directory.

## Files

| ARM Template | Source Bicep | Description |
|--------------|--------------|-------------|
| `main.json` | `main.bicep` | **Main orchestration template** - Deploys the complete solution including all sub-modules |
| `main.parameters.json` | `main.parameters.json` | **Parameters file** - Configuration values for the main template |
| `vnet.json` | `vnet.bicep` | Virtual Network, subnets, and Network Security Groups |
| `apim.json` | `apim.bicep` | Azure API Management Premium V2 service |
| `appgw.json` | `appgw.bicep` | Application Gateway with WAF configuration |
| `apimsworkspace.json` | `apimsworkspace.bicep` | APIM Workspace and VNet-injected Workspace Gateway |

## Usage

### Deploy using Azure CLI

```bash
# Deploy the complete solution using main template
az deployment group create \
  --resource-group rg_apim_workspace \
  --template-file main.json \
  --parameters @main.parameters.json

# Or deploy individual components
az deployment group create \
  --resource-group rg_apim_workspace \
  --template-file vnet.json \
  --parameters location=uksouth vnetName=vnet-apim
```

### Deploy using Azure PowerShell

```powershell
# Deploy the complete solution
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg_apim_workspace" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "main.parameters.json"
```

### Deploy using Azure Portal

1. Go to Azure Portal → Create a resource → Template deployment
2. Select "Build your own template in the editor"
3. Copy and paste the content of `main.json`
4. Configure parameters or upload `main.parameters.json`
5. Deploy to your resource group

## Template Hierarchy

The `main.json` template is the orchestrator that calls the other templates as nested deployments:

```
main.json
├── vnet.json (embedded as nested deployment)
├── apim.json (embedded as nested deployment)  
├── appgw.json (embedded as nested deployment)
└── apimsworkspace.json (embedded as nested deployment)
```

## Cost Warning

⚠️ **These templates deploy expensive Azure resources. Review the main README.md for cost information before deployment.**

## Generation

These ARM templates are automatically generated from Bicep files using:

```bash
az bicep build --file <bicep-file> --outfile arm-templates/<output-file>
```

To regenerate all templates:

```bash
cd ../
az bicep build --file main.bicep --outfile arm-templates/main.json
az bicep build --file apim.bicep --outfile arm-templates/apim.json
az bicep build --file vnet.bicep --outfile arm-templates/vnet.json
az bicep build --file appgw.bicep --outfile arm-templates/appgw.json
az bicep build --file apimsworkspace.bicep --outfile arm-templates/apimsworkspace.json
```
