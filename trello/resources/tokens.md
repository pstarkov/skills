# Tokens Endpoints

Total: 8 endpoints

## GET Requests

### Get a Token

**Operation ID:** `get-tokens-token`

**Endpoint:** `GET /tokens/{token}`

**Description:** Retrieve information about a token.

**Functions:**
- **Bash:** `trello_get_token`
- **PowerShell:** `Invoke-TrelloGetToken`

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
- **Bash:** `trello_get_tokens_member`
- **PowerShell:** `Invoke-TrelloGetTokensMember`

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
- **Bash:** `trello_get_webhooks_for_token`
- **PowerShell:** `Invoke-TrelloGetWebhooksForToken`

---

### Get a Webhook belonging to a Token

**Operation ID:** `get-tokens-token-webhooks-idwebhook`

**Endpoint:** `GET /tokens/{token}/webhooks/{idWebhook}`

**Description:** Retrieve a webhook created with a Token.

**Functions:**
- **Bash:** `trello_get_webhook_belonging_to_token`
- **PowerShell:** `Invoke-TrelloGetWebhookBelongingToToken`

---

## POST Requests

### Create Webhooks for Token

**Operation ID:** `post-tokens-token-webhooks`

**Endpoint:** `POST /tokens/{token}/webhooks`

**Description:** Create a new webhook for a Token.

**Functions:**
- **Bash:** `trello_create_webhooks_for_token`
- **PowerShell:** `Invoke-TrelloCreateWebhooksForToken`

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
- **Bash:** `trello_update_webhook_created_by_token`
- **PowerShell:** `Invoke-TrelloUpdateWebhookCreatedByToken`

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
- **Bash:** `trello_delete_token`
- **PowerShell:** `Invoke-TrelloDeleteToken`

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
- **Bash:** `trello_delete_webhook_created_by_token`
- **PowerShell:** `Invoke-TrelloDeleteWebhookCreatedByToken`

---
