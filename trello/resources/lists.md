# Lists Endpoints

Total: 11 endpoints

## GET Requests

### Get a List

**Operation ID:** `get-lists-id`

**Endpoint:** `GET /lists/{id}`

**Description:** Get information about a List

**Functions:**
- **Bash:** `get_list`
- **PowerShell:** `Invoke-GetList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get Actions for a List

**Operation ID:** `get-lists-id-actions`

**Endpoint:** `GET /lists/{id}/actions`

**Description:** Get the Actions on a List

**Functions:**
- **Bash:** `get_actions_for_list`
- **PowerShell:** `Invoke-GetActionsForList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |

---

### Get the Board a List is on

**Operation ID:** `get-lists-id-board`

**Endpoint:** `GET /lists/{id}/board`

**Description:** Get the board a list is on

**Functions:**
- **Bash:** `get_board_list_is_on`
- **PowerShell:** `Invoke-GetBoardListIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get Cards in a List

**Operation ID:** `get-lists-id-cards`

**Endpoint:** `GET /lists/{id}/cards`

**Description:** List the cards in a list

**Functions:**
- **Bash:** `get_cards_in_list`
- **PowerShell:** `Invoke-GetCardsInList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

## POST Requests

### Create a new List

**Operation ID:** `post-lists`

**Endpoint:** `POST /lists`

**Description:** Create a new List on a Board

**Functions:**
- **Bash:** `create_new_list`
- **PowerShell:** `Invoke-CreateNewList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | Yes |
| idBoard | string | query | Yes |
| idListSource | string | query | No |
| pos | string | query | No |

---

### Archive all Cards in List

**Operation ID:** `post-lists-id-archiveallcards`

**Endpoint:** `POST /lists/{id}/archiveAllCards`

**Description:** Archive all cards in a list

**Functions:**
- **Bash:** `archive_all_cards_in_list`
- **PowerShell:** `Invoke-ArchiveAllCardsInList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Move all Cards in List

**Operation ID:** `post-lists-id-moveallcards`

**Endpoint:** `POST /lists/{id}/moveAllCards`

**Description:** Move all Cards in a List

**Functions:**
- **Bash:** `move_all_cards_in_list`
- **PowerShell:** `Invoke-MoveAllCardsInList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idBoard | string | query | Yes |
| idList | string | query | Yes |

---

## PUT Requests

### Update a List

**Operation ID:** `put-lists-id`

**Endpoint:** `PUT /lists/{id}`

**Description:** Update the properties of a List

**Functions:**
- **Bash:** `update_list`
- **PowerShell:** `Invoke-UpdateList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| closed | boolean | query | No |
| idBoard | string | query | No |
| pos | string | query | No |
| subscribed | boolean | query | No |

---

### Archive or unarchive a list

**Operation ID:** `put-lists-id-closed`

**Endpoint:** `PUT /lists/{id}/closed`

**Functions:**
- **Bash:** `archive_or_unarchive_list`
- **PowerShell:** `Invoke-ArchiveOrUnarchiveList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | No |

---

### Move List to Board

**Operation ID:** `put-id-idboard`

**Endpoint:** `PUT /lists/{id}/idBoard`

**Description:** Move a List to a different Board

**Functions:**
- **Bash:** `move_list_to_board`
- **PowerShell:** `Invoke-MoveListToBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | Yes |

---

### Update a field on a List

**Operation ID:** `put-lists-id-field`

**Endpoint:** `PUT /lists/{id}/{field}`

**Description:** Rename a list

**Functions:**
- **Bash:** `update_field_on_list`
- **PowerShell:** `Invoke-UpdateFieldOnList`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |
| value | string | query | No |

---
