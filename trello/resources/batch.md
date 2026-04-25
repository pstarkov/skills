# Batch Endpoints

Total: 1 endpoints

## GET Requests

### Batch Requests

**Operation ID:** `get-batch`

**Endpoint:** `GET /batch`

**Description:** Make up to 10 GET requests in a single, batched API call.

**Functions:**
- **Bash:** `batch_requests`
- **PowerShell:** `Invoke-BatchRequests`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| urls | string | query | Yes |

---
