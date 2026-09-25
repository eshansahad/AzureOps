#  AzureOps Portal

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen?style=for-the-badge&logo=githubactions)](https://github.com/actions)
[![Node.js Version](https://img.shields.io/badge/node-20.x-339933?style=for-the-badge&logo=nodedotjs)](https://nodejs.org)
[![Azure App Service](https://img.shields.io/badge/Azure-App%20Service-0089D6?style=for-the-badge&logo=microsoftazure)](https://azure.microsoft.com/)
[![Application Insights](https://img.shields.io/badge/Telemetry-App%20Insights-8B5CF6?style=for-the-badge&logo=azuremonitor)](https://azure.microsoft.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

AzureOps is a highly engineered, production-ready cloud administration portal designed for zero-latency deployment tracking and real-time infrastructure telemetry. Built with a modern Node.js/Express backend and a geometric, high-density frontend, it provides operators with instant operational awareness without the overhead of heavy SPA frameworks.

---

##  Key Features

*   **Real-Time Telemetry Sparklines:** Hardware-accelerated, rolling-window visualizations for CPU and Memory utilization.
*   **Vertical Audit Timeline:** Chronological deployment history with relative time formatting, graceful empty states, and dynamic status nodes.
*   **Geometric Environment Grid:** Responsive CSS-grid architecture featuring stenciled typography and visual status indicators (Active/Decommissioned).
*   **Enterprise Security:** Hardened Express backend with automated rate-limiting (`express-rate-limit`) and HTTP security headers (`helmet`).
*   **Global Client Telemetry:** Native Azure Application Insights integration mapping front-end performance and user traffic.
*   **Dual-Deployment Strategy:** CI/CD pipelines configured for both raw App Service code deployments (speed) and Docker containerization (portability).

---

##  System Architecture

The portal leverages an event-driven, decoupled microservices architecture utilizing Azure Service Bus for reliable background task processing.

```mermaid
graph TD
    %% Define Styles
    classDef client fill:#1e293b,stroke:#3b82f6,stroke-width:2px,color:#f8fafc;
    classDef azureApp fill:#0078D4,stroke:#005A9E,stroke-width:2px,color:#ffffff;
    classDef messaging fill:#107C10,stroke:#0B5A0B,stroke-width:2px,color:#ffffff;
    classDef database fill:#00BCF2,stroke:#008AAB,stroke-width:2px,color:#ffffff;
    classDef monitor fill:#8B5CF6,stroke:#6D28D9,stroke-width:2px,color:#ffffff;

    %% Nodes
    Client[🖥️ Browser / Operator]:::client
    WebApp[⚡ Node.js Express API <br/> Azure App Service]:::azureApp
    AppInsights[📊 Application Insights <br/> Live Telemetry]:::monitor
    ServiceBus[📨 Azure Service Bus <br/> Deployment Queue]:::messaging
    Worker[⚙️ Background Worker <br/> processDeployment.js]:::azureApp
    SQLDB[🗄️ Azure SQL Database <br/> dbo.Deployments]:::database

    %% Connections
    Client -- HTTP GET/POST --> WebApp
    Client -. Client-Side Telemetry .-> AppInsights
    WebApp -. Server-Side Telemetry .-> AppInsights
    WebApp -- Publishes Event --> ServiceBus
    ServiceBus -- Triggers --> Worker
    Worker -- Read / Write --> SQLDB
    WebApp -- 5s Auto-Polling --> SQLDB

```

---

##  Tech Stack

| Domain | Technology | Purpose |
| --- | --- | --- |
| **Frontend** | HTML5, CSS3, Vanilla JS | High-density, zero-dependency geometric UI |
| **Data Viz** | Chart.js | Hardware telemetry sparklines |
| **Backend** | Node.js, Express.js | High-throughput REST API |
| **Database** | Azure SQL | Relational state and audit logs |
| **Messaging** | Azure Service Bus | Decoupled deployment queue |
| **DevOps** | GitHub Actions (OIDC) | Automated CI/CD pipelines |
| **Observability** | Azure Application Insights | Full-stack performance monitoring |

---

##  Getting Started

### Prerequisites

* Node.js v20+
* An active Azure Subscription (App Service, SQL, Service Bus)
* Git

### Local Installation

1. **Clone the repository**
```bash
git clone [https://github.com/your-username/AzureOps.git](https://github.com/your-username/AzureOps.git)
cd AzureOps

```


2. **Install dependencies**
```bash
cd app
npm install

```


3. **Configure Environment Variables**
Create a `.env` file in the root of the `app` directory and populate it with your Azure connection strings:
```env
PORT=3000
AZURE_SQL_CONNECTION_STRING="Server=tcp:your-server.database.windows.net,1433;Database=your-db;..."
SERVICE_BUS_CONNECTION_STRING="Endpoint=sb://your-namespace.servicebus.windows.net/;..."
APPINSIGHTS_INSTRUMENTATIONKEY="your-instrumentation-key"

```


4. **Run the development server**
```bash
npm run dev

```


The portal will be available at `http://localhost:3000`.

---

##  Deployment Strategy

This repository supports two parallel deployment models via GitHub Actions:

1. **App Service (Code Deployment):** Optimized for speed and rapid iteration. Pushes raw Node.js files directly to Azure's managed runtime.
2. **Container Apps (Docker):** Optimized for enterprise portability and immutability. Builds a sterile Linux container image pushed to Azure Container Registry (ACR).

All workflows are secured via **OIDC (OpenID Connect)**, completely eliminating the need for long-lived static credentials or secrets.

---

##  Security Posture

* **Rate Limiting:** Enforced at the Express router level (Max 100 requests / 15 minutes per IP).
* **HTTP Headers:** Strict Cross-Origin Resource Sharing (CORS) and content policies managed via `helmet`.
* **Authentication:** Infrastructure supports zero-code enterprise single sign-on (SSO) via Microsoft Entra ID (Azure EasyAuth).

---