// =====================================================================
// AzureOps Functions — SQL Database helper
// Same pattern as app/db.js: connection details come from App Settings,
// which originate from Key Vault via the Bicep parameters file.
// =====================================================================

const sql = require('mssql');

const config = {
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: true,
    trustServerCertificate: false
  },
  pool: {
    max: 5,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

let poolPromise;

function getPool() {
  if (!config.server || !config.database) {
    return Promise.reject(new Error('Database environment variables are not configured.'));
  }
  if (!poolPromise) {
    poolPromise = new sql.ConnectionPool(config).connect();
  }
  return poolPromise;
}

module.exports = { sql, getPool };
