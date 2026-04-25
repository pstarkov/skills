# Webhooks Endpoints

Total: 5 endpoints

## GET Requests

### Get a Webhook

**Operation ID:** `get-webhooks-id`

**Endpoint:** `GET /webhooks/{id}`

**Description:** Get a webhook by ID. You must use the token query parameter and pass in the token the webhook was created under, or else you will encounter a 'webhook does not belong to token' error.

**Functions:**
- **Bash:** `get_webhook`
- **PowerShell:** `Invoke-GetWebhook`

---

### Get a field on a Webhook

**Operation ID:** `webhooksidfield`

**Endpoint:** `GET /webhooks/{id}/{field}`

**Functions:**
- **Bash:** `get_field_on_webhook`
- **PowerShell:** `Invoke-GetFieldOnWebhook`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Create a Webhook

**Operation ID:** `post-webhooks`

**Endpoint:** `POST /webhooks/`

**Description:** Create a new webhook.

**Functions:**
- **Bash:** `create_webhook`
- **PowerShell:** `Invoke-CreateWebhook`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| description | string | query | No |
| callbackURL | string | query | Yes |
| idModel | string | query | Yes |
| active | boolean | query | No |

---

## PUT Requests

### Update a Webhook

**Operation ID:** `put-webhooks-id`

**Endpoint:** `PUT /webhooks/{id}`

**Description:** Update a webhook by ID.

**Functions:**
- **Bash:** `update_webhook`
- **PowerShell:** `Invoke-UpdateWebhook`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| description | string | query | No |
| callbackURL | string | query | No |
| idModel | string | query | No |
| active | boolean | query | No |

---

## DELETE Requests

### Delete a Webhook

**Operation ID:** `delete-webhooks-id`

**Endpoint:** `DELETE /webhooks/{id}`

**Description:** Delete a webhook by ID.

**Functions:**
- **Bash:** `delete_webhook`
- **PowerShell:** `Invoke-DeleteWebhook`

---
