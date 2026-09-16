// functions/src/reportStorage.js
// Uploads a JSON report blob for each processed deployment, using managed
// identity (no account key/connection string). Import from
// processDeployment.js and call after the SQL write succeeds.

const { BlobServiceClient } = require('@azure/storage-blob');
const { DefaultAzureCredential } = require('@azure/identity');

const BLOB_ENDPOINT = process.env.REPORTS_BLOB_ENDPOINT; // e.g. https://<account>.blob.core.windows.net
const CONTAINER_NAME = process.env.REPORTS_CONTAINER_NAME || 'deployment-reports';

let containerClient;
function getContainerClient() {
    if (!containerClient) {
        const blobServiceClient = new BlobServiceClient(BLOB_ENDPOINT, new DefaultAzureCredential());
        containerClient = blobServiceClient.getContainerClient(CONTAINER_NAME);
    }
    return containerClient;
}

/**
 * @param {number|string} deploymentId
 * @param {object} report  the deployment record / summary to persist
 */
async function uploadDeploymentReport(deploymentId, report) {
    if (!BLOB_ENDPOINT) {
        console.warn('REPORTS_BLOB_ENDPOINT not set — skipping report upload');
        return;
    }
    try {
        const blobName = `deployments/${deploymentId}.json`;
        const blockBlobClient = getContainerClient().getBlockBlobClient(blobName);
        const content = JSON.stringify(report, null, 2);
        await blockBlobClient.upload(content, Buffer.byteLength(content), {
            blobHTTPHeaders: { blobContentType: 'application/json' }
        });
    } catch (err) {
        // A failed upload should never fail the primary operation — the SQL
        // write and event publish already succeeded. Log and move on.
        console.error(`Failed to upload report for deployment ${deploymentId}:`, err.message);
    }
}

module.exports = { uploadDeploymentReport };
