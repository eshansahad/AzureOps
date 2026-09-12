// ============================================================================
// AzureOps Functions - SQL Database helper with Auto-Recovery
// ============================================================================

const sql = require('mssql');

const config = {
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: true,
    trustServerCertificate: false,
    connectTimeout: 30000,
    requestTimeout: 30000
  },
  pool: {
    max: 5,
    min: 0,
    idleTimeoutMillis: 10000
  }
};

let pool = null;

async function getPool() {
  if (!config.server || !config.database) {
    throw new Error('Database environment variables are not configured.');
  }

  // If pool exists, verify it is still healthy
  if (pool) {
    try {
      await pool.request().query('SELECT 1 AS health');
      return pool;
    } catch (err) {
      try {
        await pool.close();
      } catch (_) {}
      pool = null;
    }
  }

  // Create fresh pool if missing or after dropped socket
  pool = await new sql.ConnectionPool(config).connect();
  pool.on('error', (err) => {
    pool = null;
  });

  return pool;
}

module.exports = { sql, getPool };