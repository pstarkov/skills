# Checklists Endpoints

Total: 12 endpoints

## GET Requests

### Get a Checklist

**Operation ID:** `get-checklists-id`

**Endpoint:** `GET /checklists/{id}`

**Functions:**
- **Bash:** `get_checklist`
- **PowerShell:** `Invoke-GetChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| cards | string | query | No |
| checkItems | string | query | No |
| checkItem_fields | string | query | No |
| fields | string | query | No |

---

### Get the Board the Checklist is on

**Operation ID:** `get-checklists-id-board`

**Endpoint:** `GET /checklists/{id}/board`

**Functions:**
- **Bash:** `get_board_checklist_is_on`
- **PowerShell:** `Invoke-GetBoardChecklistIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Card a Checklist is on

**Operation ID:** `get-checklists-id-cards`

**Endpoint:** `GET /checklists/{id}/cards`

**Functions:**
- **Bash:** `get_card_checklist_is_on`
- **PowerShell:** `Invoke-GetCardChecklistIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Checkitems on a Checklist

**Operation ID:** `get-checklists-id-checkitems`

**Endpoint:** `GET /checklists/{id}/checkItems`

**Functions:**
- **Bash:** `get_checkitems_on_checklist`
- **PowerShell:** `Invoke-GetCheckitemsOnChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| filter | string | query | No |
| fields | string | query | No |

---

### Get a Checkitem on a Checklist

**Operation ID:** `get-checklists-id-checkitems-idcheckitem`

**Endpoint:** `GET /checklists/{id}/checkItems/{idCheckItem}`

**Functions:**
- **Bash:** `get_checkitem_on_checklist`
- **PowerShell:** `Invoke-GetCheckitemOnChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get field on a Checklist

**Operation ID:** `get-checklists-id-field`

**Endpoint:** `GET /checklists/{id}/{field}`

**Functions:**
- **Bash:** `get_field_on_checklist`
- **PowerShell:** `Invoke-GetFieldOnChecklist`

---

## POST Requests

### Create a Checklist

**Operation ID:** `post-checklists`

**Endpoint:** `POST /checklists`

**Functions:**
- **Bash:** `create_checklist`
- **PowerShell:** `Invoke-CreateChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idCard | string | query | Yes |
| name | string | query | No |
| pos | string | query | No |
| idChecklistSource | string | query | No |

---

### Create Checkitem on Checklist

**Operation ID:** `post-checklists-id-checkitems`

**Endpoint:** `POST /checklists/{id}/checkItems`

**Functions:**
- **Bash:** `create_checkitem_on_checklist`
- **PowerShell:** `Invoke-CreateCheckitemOnChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | Yes |
| pos | string | query | No |
| checked | boolean | query | No |
| due | string | query | No |
| dueReminder | number | query | No |
| idMember | string | query | No |

---

## PUT Requests

### Update a Checklist

**Operation ID:** `put-checlists-id`

**Endpoint:** `PUT /checklists/{id}`

**Description:** Update an existing checklist.

**Functions:**
- **Bash:** `update_checklist`
- **PowerShell:** `Invoke-UpdateChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| pos | string | query | No |

---

### Update field on a Checklist

**Operation ID:** `put-checklists-id-field`

**Endpoint:** `PUT /checklists/{id}/{field}`

**Functions:**
- **Bash:** `update_field_on_checklist`
- **PowerShell:** `Invoke-UpdateFieldOnChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| value | string | query | Yes |

---

## DELETE Requests

### Delete a Checklist

**Operation ID:** `delete-checklists-id`

**Endpoint:** `DELETE /checklists/{id}`

**Description:** Delete a checklist

**Functions:**
- **Bash:** `delete_checklist`
- **PowerShell:** `Invoke-DeleteChecklist`

---

### Delete Checkitem from Checklist

**Operation ID:** `delete-checklists-id-checkitems-idcheckitem`

**Endpoint:** `DELETE /checklists/{id}/checkItems/{idCheckItem}`

**Description:** Remove an item from a checklist

**Functions:**
- **Bash:** `delete_checkitem_from_checklist`
- **PowerShell:** `Invoke-DeleteCheckitemFromChecklist`

---
