# Checklists Endpoints

Total: 12 endpoints

## GET Requests

### Get a Checklist

**Operation ID:** `get-checklists-id`

**Endpoint:** `GET /checklists/{id}`

**Functions:**
- **Bash:** `trello_get_checklist`
- **PowerShell:** `Invoke-TrelloGetChecklist`

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
- **Bash:** `trello_get_board_checklist_is_on`
- **PowerShell:** `Invoke-TrelloGetBoardChecklistIsOn`

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
- **Bash:** `trello_get_card_checklist_is_on`
- **PowerShell:** `Invoke-TrelloGetCardChecklistIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Checkitems on a Checklist

**Operation ID:** `get-checklists-id-checkitems`

**Endpoint:** `GET /checklists/{id}/checkItems`

**Functions:**
- **Bash:** `trello_get_checkitems_on_checklist`
- **PowerShell:** `Invoke-TrelloGetCheckitemsOnChecklist`

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
- **Bash:** `trello_get_checkitem_on_checklist`
- **PowerShell:** `Invoke-TrelloGetCheckitemOnChecklist`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get field on a Checklist

**Operation ID:** `get-checklists-id-field`

**Endpoint:** `GET /checklists/{id}/{field}`

**Functions:**
- **Bash:** `trello_get_field_on_checklist`
- **PowerShell:** `Invoke-TrelloGetFieldOnChecklist`

---

## POST Requests

### Create a Checklist

**Operation ID:** `post-checklists`

**Endpoint:** `POST /checklists`

**Functions:**
- **Bash:** `trello_create_checklist`
- **PowerShell:** `Invoke-TrelloCreateChecklist`

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
- **Bash:** `trello_create_checkitem_on_checklist`
- **PowerShell:** `Invoke-TrelloCreateCheckitemOnChecklist`

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
- **Bash:** `trello_update_checklist`
- **PowerShell:** `Invoke-TrelloUpdateChecklist`

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
- **Bash:** `trello_update_field_on_checklist`
- **PowerShell:** `Invoke-TrelloUpdateFieldOnChecklist`

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
- **Bash:** `trello_delete_checklist`
- **PowerShell:** `Invoke-TrelloDeleteChecklist`

---

### Delete Checkitem from Checklist

**Operation ID:** `delete-checklists-id-checkitems-idcheckitem`

**Endpoint:** `DELETE /checklists/{id}/checkItems/{idCheckItem}`

**Description:** Remove an item from a checklist

**Functions:**
- **Bash:** `trello_delete_checkitem_from_checklist`
- **PowerShell:** `Invoke-TrelloDeleteCheckitemFromChecklist`

---
