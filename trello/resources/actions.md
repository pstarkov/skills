# Actions Endpoints

Total: 16 endpoints

## GET Requests

### Get Action's Reactions

**Operation ID:** `get-actions-idaction-reactions`

**Endpoint:** `GET /actions/{idAction}/reactions`

**Description:** List reactions for an action

**Functions:**
- **Bash:** `trello_get_actions_reactions`
- **PowerShell:** `Invoke-TrelloGetActionsReactions`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| member | boolean | query | No |
| emoji | boolean | query | No |

---

### Get Action's Reaction

**Operation ID:** `get-actions-idaction-reactions-id`

**Endpoint:** `GET /actions/{idAction}/reactions/{id}`

**Description:** Get information for a reaction

**Functions:**
- **Bash:** `trello_get_actions_reaction`
- **PowerShell:** `Invoke-TrelloGetActionsReaction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| member | boolean | query | No |
| emoji | boolean | query | No |

---

### List Action's summary of Reactions

**Operation ID:** `get-actions-idaction-reactionsummary`

**Endpoint:** `GET /actions/{idAction}/reactionsSummary`

**Description:** List a summary of all reactions for an action

**Functions:**
- **Bash:** `trello_list_actions_summary_reactions`
- **PowerShell:** `Invoke-TrelloListActionsSummaryReactions`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idAction | string | path | Yes |

---

### Get an Action

**Operation ID:** `get-actions-id`

**Endpoint:** `GET /actions/{id}`

**Functions:**
- **Bash:** `trello_get_action`
- **PowerShell:** `Invoke-TrelloGetAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| display | boolean | query | No |
| entities | boolean | query | No |
| fields | string | query | No |
| member | boolean | query | No |
| member_fields | string | query | No |
| memberCreator | boolean | query | No |
| memberCreator_fields | string | query | No |

---

### Get the Board for an Action

**Operation ID:** `get-actions-id-board`

**Endpoint:** `GET /actions/{id}/board`

**Functions:**
- **Bash:** `trello_get_board_for_action`
- **PowerShell:** `Invoke-TrelloGetBoardForAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Card for an Action

**Operation ID:** `get-actions-id-card`

**Endpoint:** `GET /actions/{id}/card`

**Description:** Get the card for an action

**Functions:**
- **Bash:** `trello_get_card_for_action`
- **PowerShell:** `Invoke-TrelloGetCardForAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the List for an Action

**Operation ID:** `get-actions-id-list`

**Endpoint:** `GET /actions/{id}/list`

**Functions:**
- **Bash:** `trello_get_list_for_action`
- **PowerShell:** `Invoke-TrelloGetListForAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Member of an Action

**Operation ID:** `get-actions-id-member`

**Endpoint:** `GET /actions/{id}/member`

**Description:** Gets the member of an action (not the creator)

**Functions:**
- **Bash:** `trello_get_member_action`
- **PowerShell:** `Invoke-TrelloGetMemberAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Member Creator of an Action

**Operation ID:** `get-actions-id-membercreator`

**Endpoint:** `GET /actions/{id}/memberCreator`

**Description:** Get the Member who created the Action

**Functions:**
- **Bash:** `trello_get_member_creator_action`
- **PowerShell:** `Invoke-TrelloGetMemberCreatorAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Organization of an Action

**Operation ID:** `get-actions-id-organization`

**Endpoint:** `GET /actions/{id}/organization`

**Functions:**
- **Bash:** `trello_get_organization_action`
- **PowerShell:** `Invoke-TrelloGetOrganizationAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get a specific field on an Action

**Operation ID:** `get-actions-id-field`

**Endpoint:** `GET /actions/{id}/{field}`

**Description:** Get a specific property of an action

**Functions:**
- **Bash:** `trello_get_specific_field_on_action`
- **PowerShell:** `Invoke-TrelloGetSpecificFieldOnAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Create Reaction for Action

**Operation ID:** `post-actions-idaction-reactions`

**Endpoint:** `POST /actions/{idAction}/reactions`

**Description:** Adds a new reaction to an action

**Functions:**
- **Bash:** `trello_create_reaction_for_action`
- **PowerShell:** `Invoke-TrelloCreateReactionForAction`

---

## PUT Requests

### Update an Action

**Operation ID:** `put-actions-id`

**Endpoint:** `PUT /actions/{id}`

**Description:** Update a specific Action. Only comment actions can be updated. Used to edit the content of a comment.

**Functions:**
- **Bash:** `trello_update_action`
- **PowerShell:** `Invoke-TrelloUpdateAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| text | string | query | Yes |

---

### Update a Comment Action

**Operation ID:** `put-actions-id-text`

**Endpoint:** `PUT /actions/{id}/text`

**Description:** Update a comment action

**Functions:**
- **Bash:** `trello_update_comment_action`
- **PowerShell:** `Invoke-TrelloUpdateCommentAction`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | Yes |

---

## DELETE Requests

### Delete Action's Reaction

**Operation ID:** `delete-actions-idaction-reactions-id`

**Endpoint:** `DELETE /actions/{idAction}/reactions/{id}`

**Description:** Deletes a reaction

**Functions:**
- **Bash:** `trello_delete_actions_reaction`
- **PowerShell:** `Invoke-TrelloDeleteActionsReaction`

---

### Delete an Action

**Operation ID:** `delete-actions-id`

**Endpoint:** `DELETE /actions/{id}`

**Description:** Delete a specific action. Only comment actions can be deleted.

**Functions:**
- **Bash:** `trello_delete_action`
- **PowerShell:** `Invoke-TrelloDeleteAction`

---
