-- =====================================================================
-- AzureOps — Core Database Schema
-- Target: sqldb-azureops-dev (Azure SQL Database)
-- Run via: Query Editor (Azure Portal), sqlcmd, or the deploy-schema
-- GitHub Actions workflow (.github/workflows/deploy-schema.yml)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Users: represents Developer, DevOps Engineer, and Cloud Administrator
-- personas. Role maps conceptually to the Azure RBAC role assigned on
-- the resource group (Reader / Contributor / Owner).
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        UserId          INT IDENTITY(1,1) PRIMARY KEY,
        DisplayName     NVARCHAR(100)   NOT NULL,
        Email           NVARCHAR(256)   NOT NULL UNIQUE,
        Role            NVARCHAR(50)    NOT NULL, -- Developer | DevOpsEngineer | CloudAdministrator
        CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

-- ---------------------------------------------------------------------
-- Environments: Dev / Test / Stage / Prod environment records.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Environments')
BEGIN
    CREATE TABLE Environments (
        EnvironmentId   INT IDENTITY(1,1) PRIMARY KEY,
        Name            NVARCHAR(100)   NOT NULL,
        EnvironmentType NVARCHAR(20)    NOT NULL, -- Dev | Test | Stage | Prod
        Status          NVARCHAR(30)    NOT NULL DEFAULT 'Active',
        OwnerUserId     INT             NULL REFERENCES Users(UserId),
        CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

-- ---------------------------------------------------------------------
-- Deployments: records each application deployment event.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Deployments')
BEGIN
    CREATE TABLE Deployments (
        DeploymentId    INT IDENTITY(1,1) PRIMARY KEY,
        EnvironmentId   INT             NOT NULL REFERENCES Environments(EnvironmentId),
        AppName         NVARCHAR(150)   NOT NULL,
        Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending', -- Pending | Succeeded | Failed
        TriggeredByUserId INT           NULL REFERENCES Users(UserId),
        StartedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
        CompletedAt     DATETIME2       NULL
    );
END
GO

-- ---------------------------------------------------------------------
-- Incidents: detection + remediation record, tied to a deployment
-- and/or environment. Populated by the Azure Function remediation
-- workflow described in the architecture.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Incidents')
BEGIN
    CREATE TABLE Incidents (
        IncidentId      INT IDENTITY(1,1) PRIMARY KEY,
        EnvironmentId   INT             NULL REFERENCES Environments(EnvironmentId),
        DeploymentId    INT             NULL REFERENCES Deployments(DeploymentId),
        Description     NVARCHAR(500)   NOT NULL,
        Severity        NVARCHAR(20)    NOT NULL DEFAULT 'Medium', -- Low | Medium | High | Critical
        Status          NVARCHAR(30)    NOT NULL DEFAULT 'Open',   -- Open | Mitigating | Resolved
        ActionTaken     NVARCHAR(500)   NULL,
        DetectedAt      DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
        ResolvedAt      DATETIME2       NULL
    );
END
GO

-- ---------------------------------------------------------------------
-- Seed data: one row per persona, matching the Entra ID users created
-- for the project (dev-user, devops-user, admin-user).
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM Users WHERE Email = 'dev-user@azure.certifiedyapper.quest')
BEGIN
    INSERT INTO Users (DisplayName, Email, Role) VALUES
        ('dev-user', 'dev-user@azure.certifiedyapper.quest', 'Developer'),
        ('devops-user', 'devops-user@azure.certifiedyapper.quest', 'DevOpsEngineer'),
        ('admin-user', 'admin-user@azure.certifiedyapper.quest', 'CloudAdministrator');
END
GO
