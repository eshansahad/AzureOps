# AzureOps — Enterprise Cloud Operations Platform

A centralized Azure platform for application deployment, environment management, monitoring, incident response, and cloud automation — built to demonstrate practical Cloud/DevOps engineering across 10+ Azure services.

> This repository is the Infrastructure-as-Code and automation source of truth for the AzureOps project. Resources are defined in Bicep, database schema is version-controlled, and deployments are driven by GitHub Actions.

## Architecture

```
USERS: Developer | DevOps Engineer | Cloud Administrator
        │
        ▼
Microsoft Entra ID + RBAC
        │
        ▼
AzureOps Portal (Azure App Service)
        │
        ▼
API Management
        │
   ┌────┼────────────┐
   ▼    ▼             ▼
Functions  SQL DB    Storage
   │
Event Grid / Service Bus
   │
Application Insights → Azure Monitor → Log Analytics → Alerts → Remediation
```

Security: Azure Key Vault + Managed Identity + RBAC
CI/CD: GitHub → GitHub Actions → Build/Test → Azure Deployment

## Repository structure

```
AzureOps/
├── infra/                      # Infrastructure as Code (Bicep)
│   ├── main.bicep              # Subscription-scoped entry point
│   ├── main.parameters.dev.json
│   └── modules/
│       ├── keyvault.bicep      # Key Vault (Azure RBAC permission model)
│       └── sql.bicep           # SQL Server + Serverless Database
├── sql/
│   └── schema.sql              # Core tables: Users, Environments, Deployments, Incidents
├── .github/workflows/
│   ├── deploy-infra.yml        # Validates + deploys Bicep on push to infra/
│   └── deploy-schema.yml       # Applies schema.sql on push to sql/
└── docs/                       # Architecture notes, screenshots, report assets
```

## Provisioned resources (Phase 2–3)

| Resource | Name | Notes |
|---|---|---|
| Resource Group | `rg-azureops-dev` | East US |
| Entra ID App | `AzureOps-Portal` | Single tenant |
| Custom Domain | `azure.certifiedyapper.quest` | Verified via TXT record |
| Key Vault | `kv-azureops-dev` | Azure RBAC permission model |
| SQL Server | `sql-azureops-dev` | West US (region moved due to free-tier quota on East US) |
| SQL Database | `sqldb-azureops-dev` | General Purpose Serverless, auto-pause 1h |

## Identity & access model

| Persona | Entra ID User | Azure RBAC Role (on `rg-azureops-dev`) |
|---|---|---|
| Cloud Administrator | `admin-user` | Owner |
| DevOps Engineer | `devops-user` | Contributor |
| Developer | `dev-user` | Reader |

Secrets (SQL admin password, connection strings) are stored in `kv-azureops-dev` and never committed to this repository.

## Deploying infrastructure

```bash
az login
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.json
```

Or let GitHub Actions handle it automatically on push to `infra/**` (see `.github/workflows/deploy-infra.yml`). Requires the following repository secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `SQL_ADMIN_PASSWORD`, `CLIENT_IP_ADDRESS`.

## Applying the database schema

```bash
sqlcmd -S sql-azureops-dev.database.windows.net -d sqldb-azureops-dev -U eshan -P <password> -i sql/schema.sql -N -C
```

Or push changes to `sql/**` and let `deploy-schema.yml` apply them automatically.

## Project status

This project is being built incrementally, phase by phase, with each Azure service integrated and documented as it's added. See `docs/` for the full implementation log and final project report.

## License

This is a portfolio/learning project and is not intended for production use.
