# Tokens Endpoints

Total: 8 endpoints

## GET Requests

### Get a Token

**Operation ID:** `get-tokens-token`

**Endpoint:** `GET /tokens/{token}`

**Description:** Retrieve information about a token.

**Functions:**
- **Bash:** `get_token`
- **PowerShell:** `Invoke-GetToken`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| token | string | path | Yes |
| fields | string | query | No |
| webhooks | boolean | query | No |

---

### Get Token's Member

**Operation ID:** `get-tokens-token-member`

**Endpoint:** `GET /tokens/{token}/member`

**Description:** Retrieve information about a token's owner by token.

**Functions:**
- **Bash:** `get_tokens_member`
- **PowerShell:** `Invoke-GetTokensMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| token | string | path | Yes |
| fields | string | query | No |

---

### Get Webhooks for Token

**Operation ID:** `get-tokens-token-webhooks`

**Endpoint:** `GET /tokens/{token}/webhooks`

**Description:** Retrieve all webhooks created with a Token.

**Functions:**
- **Bash:** `get_webhooks_for_token`
- **PowerShell:** `Invoke-GetWebhooksForToken`

---

### Get a Webhook belonging to a Token

**Operation ID:** `get-tokens-token-webhooks-idwebhook`

**Endpoint:** `GET /tokens/{token}/webhooks/{idWebhook}`

**Description:** Retrieve a webhook created with a Token.

**Functions:**
- **Bash:** `get_webhook_belonging_to_token`
- **PowerShell:** `Invoke-GetWebhookBelongingToToken`

---

## POST Requests

### Create Webhooks for Token

**Operation ID:** `post-tokens-token-webhooks`

**Endpoint:** `POST /tokens/{token}/webhooks`

**Description:** Create a new webhook for a Token.

**Functions:**
- **Bash:** `create_webhooks_for_token`
- **PowerShell:** `Invoke-CreateWebhooksForToken`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| description | string | query | No |
| callbackURL | string | query | Yes |
| idModel | string | query | Yes |

---

## PUT Requests

### Update a Webhook created by Token

**Operation ID:** `tokenstokenwebhooks-1`

**Endpoint:** `PUT /tokens/{token}/webhooks/{idWebhook}`

**Functions:**
- **Bash:** `update_webhook_created_by_token`
- **PowerShell:** `Invoke-UpdateWebhookCreatedByToken`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| description | string | query | No |
| callbackURL | string | query | No |
| idModel | string | query | No |

---

## DELETE Requests

### Delete a Token

**Operation ID:** `delete-token`

**Endpoint:** `DELETE /tokens/{token}/`

**Description:** Delete a token.

**Functions:**
- **Bash:** `delete_token`
- **PowerShell:** `Invoke-DeleteToken`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| token | string | path | Yes |

---

### Delete a Webhook created by Token

**Operation ID:** `delete-tokens-token-webhooks-idwebhook`

**Endpoint:** `DELETE /tokens/{token}/webhooks/{idWebhook}`

**Description:** Delete a webhook created with given token.

**Functions:**
- **Bash:** `delete_webhook_created_by_token`
- **PowerShell:** `Invoke-DeleteWebhookCreatedByToken`

---
