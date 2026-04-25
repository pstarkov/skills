# Labels Endpoints

Total: 5 endpoints

## GET Requests

### Get a Label

**Operation ID:** `get-labels-id`

**Endpoint:** `GET /labels/{id}`

**Description:** Get information about a single Label.

**Functions:**
- **Bash:** `get_label`
- **PowerShell:** `Invoke-GetLabel`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

## POST Requests

### Create a Label

**Operation ID:** `post-labels`

**Endpoint:** `POST /labels`

**Description:** Create a new Label on a Board.

**Functions:**
- **Bash:** `create_label`
- **PowerShell:** `Invoke-CreateLabel`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | Yes |
| color | string | query | Yes |
| idBoard | string | query | Yes |

---

## PUT Requests

### Update a Label

**Operation ID:** `put-labels-id`

**Endpoint:** `PUT /labels/{id}`

**Description:** Update a label by ID.

**Functions:**
- **Bash:** `update_label`
- **PowerShell:** `Invoke-UpdateLabel`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| color | string | query | No |

---

### Update a field on a label

**Operation ID:** `put-labels-id-field`

**Endpoint:** `PUT /labels/{id}/{field}`

**Description:** Update a field on a label.

**Functions:**
- **Bash:** `update_field_on_label`
- **PowerShell:** `Invoke-UpdateFieldOnLabel`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |
| value | string | query | Yes |

---

## DELETE Requests

### Delete a Label

**Operation ID:** `delete-labels-id`

**Endpoint:** `DELETE /labels/{id}`

**Description:** Delete a label by ID.

**Functions:**
- **Bash:** `delete_label`
- **PowerShell:** `Invoke-DeleteLabel`

---
