# Azure API Management Workspace with VNet-Injected Gateway

## ⚠️ **COST WARNING - READ BEFORE DEPLOYMENT** ⚠️

> **🚨 HIGH COST INFRASTRUCTURE 🚨**
> 
> **This solution deploys PREMIUM Azure resources that incur SIGNIFICANT costs:**
> - Azure API Management Premium V2 tier (~$3,000-4,000+ per month)
> - Application Gateway with WAF (~$300+ per month)
> - Workspace Gateway Premium instances (~$1,000+ per month each)
> - Virtual Network and associated networking costs
>
> **💰 ESTIMATED MONTHLY COST: $4,500-6,000+ USD**
>
> **This infrastructure should ONLY be used for:**
> - ✅ Short-term testing and exploration
> - ✅ Proof of concept development
> - ✅ Learning Azure APIM workspace architecture
>
> **❌ NOT recommended for:**
> - Long-term development environments
> - Production workloads without proper cost analysis
> - Unattended deployments
>
> **🔥 ALWAYS CLEAN UP**: Use `./undeploy.sh` to remove all resources when finished to avoid unexpected charges!

A complete Infrastructure as Code (IaC) solution for deploying Azure API Management with workspace isolation using VNet-injected gateways.

## 🏗️ Architecture Overview

This solution deploys a secure, scalable APIM workspace architecture with the following components:

```
Internet → Application Gateway (Public) → APIM (Internal VNet)
                                       ↓
                           Workspace APIs → Workspace Gateway (VNet-injected)
                                         ↓
                                    Backend Services
```

### Key Components

- **Virtual Network**: Isolated network with dedicated subnets
- **APIM Service**: Premium V2 tier with Internal VNet mode
- **Application Gateway**: WAF-enabled public endpoint
- **APIM Workspace**: Logical separation for API management
- **Workspace Gateway**: Premium VNet-injected gateway with `WorkspaceGatewayPremium` SKU
- **Configuration Connection**: Automatic linking between workspace and gateway

## 📁 Project Structure

```
workspaces/
├── infra/
│   ├── main.bicep                 # Main orchestration template
│   ├── main.parameters.json       # Deployment parameters
│   ├── vnet.bicep                # VNet, subnets, and NSGs
│   ├── apim.bicep                # APIM service configuration
│   ├── appgw.bicep               # Application Gateway setup
│   ├── apimsworkspace.bicep      # Workspace and gateway deployment
│   ├── deploy.sh                 # Deployment script
│   └── undeploy.sh               # Clean removal script
└── README.md                     # This file
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated
- Bash shell (WSL, Linux, or macOS)
- Azure subscription with contributor access
- Resource providers registered:
  - `Microsoft.ApiManagement`
  - `Microsoft.Network`

### Deployment

1. **Clone and navigate to the infrastructure directory:**
   ```bash
   cd workspaces/infra
   ```

2. **Configure deployment parameters (optional):**
   Edit `main.parameters.json` to customize:
   - Location (default: `uksouth`)
   - APIM service name prefix
   - Publisher email and name
   - VNet configuration

3. **Deploy the complete solution:**
   ```bash
   ./deploy.sh
   ```

The deployment will create all resources in a single step, including automatic configuration of the workspace-to-gateway connection.

### Undeploy

To completely remove all resources:

```bash
./undeploy.sh
```

⚠️ **Warning**: This permanently deletes all resources in the resource group.

## 🏗️ Infrastructure Details

### Network Architecture

| Subnet | CIDR | Purpose | Delegation |
|--------|------|---------|------------|
| `snet-apim` | `/27` | APIM service | `Microsoft.ApiManagement/service` |
| `snet-appgw` | `/27` | Application Gateway | None |
| `snet-workspace-1` | `/27` | Workspace Gateway | `Microsoft.Web/hostingEnvironments` |
| `snet-workspace-2` | `/27` | Future workspace | `Microsoft.Web/hostingEnvironments` |
| `snet-workspace-3` | `/27` | Future workspace | `Microsoft.Web/hostingEnvironments` |

### Security Features

- **Internal VNet Mode**: APIM not directly accessible from internet
- **NSG Rules**: Comprehensive network security groups for each subnet
- **WAF Protection**: Application Gateway with Web Application Firewall
- **Subnet Delegation**: Proper Azure service delegation for security
- **Private Networking**: All communication within VNet boundaries

### Resource Configuration

- **APIM SKU**: Premium_v2 (required for VNet integration and workspaces)
- **Gateway SKU**: WorkspaceGatewayPremium with capacity 1
- **App Gateway SKU**: WAF_v2 with autoscaling
- **VNet Mode**: Internal (private networking)

## 🔧 Customization

### Adding More Workspaces

To add additional workspaces:

1. Update `workspaceCount` in `main.parameters.json`
2. Modify `apimsworkspace.bicep` to deploy multiple workspaces
3. Each workspace can have its own dedicated gateway in separate subnets

### Scaling Gateway Capacity

Update the gateway capacity in `apimsworkspace.bicep`:

```bicep
sku: {
  name: 'WorkspaceGatewayPremium'
  capacity: 2  // Increase for higher throughput
}
```

### Custom Network Configuration

Modify `vnet.bicep` to adjust:
- VNet address space
- Subnet CIDR blocks
- NSG rules
- Additional subnets

## 📊 Monitoring and Management

### Key Endpoints

After deployment, you'll have access to:

- **Public Endpoint**: `https://<appgw-name>.<region>.cloudapp.azure.com`
- **APIM Portal**: `https://<apim-name>.portal.azure-api.net`
- **APIM Management**: `https://<apim-name>.management.azure-api.net`

### Resource Names

Resources are created with unique suffixes for conflict avoidance:

- VNet: `vnet-apim-<unique-id>`
- APIM: `apim-testcorp-<unique-id>`
- App Gateway: `appgw-apim-<unique-id>`
- Workspace: `workspace-primary`
- Gateway: `gateway-workspace-primary`

## 🔍 Troubleshooting

### Common Issues

1. **Deployment Timeout**: APIM deployment can take 45+ minutes
2. **Subnet Conflicts**: Ensure VNet CIDR doesn't conflict with existing networks
3. **Resource Provider**: Verify `Microsoft.ApiManagement` is registered
4. **Quota Limits**: Check Azure subscription limits for Premium APIM instances

### Verification Commands

Check deployment status:
```bash
# Verify APIM service
az apim show --name <apim-name> --resource-group rg_apim_workspace

# Verify workspace gateway
az rest --method GET --url "https://management.azure.com/subscriptions/<sub-id>/resourceGroups/rg_apim_workspace/providers/Microsoft.ApiManagement/gateways/gateway-workspace-primary?api-version=2024-06-01-preview"

# Verify configuration connection
az rest --method GET --url "https://management.azure.com/subscriptions/<sub-id>/resourceGroups/rg_apim_workspace/providers/Microsoft.ApiManagement/gateways/gateway-workspace-primary/configConnections/default?api-version=2024-06-01-preview"
```

## 📚 Additional Resources

- [Azure API Management Documentation](https://docs.microsoft.com/en-us/azure/api-management/)
- [APIM Workspaces Overview](https://docs.microsoft.com/en-us/azure/api-management/workspaces-overview)
- [VNet Integration Guide](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet)
- [Premium Gateway Documentation](https://docs.microsoft.com/en-us/azure/api-management/self-hosted-gateway-overview)

## 🤝 Contributing

To contribute improvements:

1. Test changes in a development environment
2. Update documentation for any new features
3. Ensure backward compatibility with existing deployments
4. Update this README with any new configuration options

## 📄 License

This project is provided as-is for educational and development purposes.

---

**Created with ❤️ for secure, scalable API management**
