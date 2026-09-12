const sql = require('mssql');

const config = {
  server: (process.env.DB_SERVER || '').trim(),
  database: (process.env.DB_DATABASE || '').trim(),
  user: (process.env.DB_USER || '').trim(),
  password: (process.env.DB_PASSWORD || '').trim(),
  port: 1433,
  connectionTimeout: 30000,
  requestTimeout: 30000,
  options: {
    encrypt: true,
    trustServerCertificate: false,
    enableArithAbort: true,
    connectTimeout: 30000,
    cryptoCredentialsDetails: {
      minVersion: 'TLSv1.2'
    }
  },
  pool: {
    max: 5,
    min: 0,
    idleTimeoutMillis: 5000,
    acquireTimeoutMillis: 30000
  }
};

let pool = null;

async function getPool() {
  if (!config.server || !config.database) {
    throw new Error('Database environment variables are not configured.');
  }

  if (pool) {
    try {
      await pool.request().query('SELECT 1 AS ping');
      return pool;
    } catch (err) {
      try {
        await pool.close();
      } catch (_) {}
      pool = null;
    }
  }

  pool = await new sql.ConnectionPool(config).connect();
  pool.on('error', (err) => {
    console.error('SQL Pool background error:', err.message);
    pool = null;
  });

  return pool;
}

module.exports = { sql, getPool };