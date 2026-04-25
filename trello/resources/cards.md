# Cards Endpoints

Total: 39 endpoints

## GET Requests

### Get a Card

**Operation ID:** `get-cards-id`

**Endpoint:** `GET /cards/{id}`

**Description:** Get a card by its ID

**Functions:**
- **Bash:** `trello_get_card`
- **PowerShell:** `Invoke-TrelloGetCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |
| actions | string | query | No |
| attachments | string | query | No |
| attachment_fields | string | query | No |
| members | boolean | query | No |
| member_fields | string | query | No |
| membersVoted | boolean | query | No |
| memberVoted_fields | string | query | No |
| checkItemStates | boolean | query | No |
| checklists | string | query | No |
| checklist_fields | string | query | No |
| board | boolean | query | No |
| board_fields | string | query | No |
| list | boolean | query | No |
| pluginData | boolean | query | No |
| stickers | boolean | query | No |
| sticker_fields | string | query | No |
| customFieldItems | boolean | query | No |

---

### Get Actions on a Card

**Operation ID:** `get-cards-id-actions`

**Endpoint:** `GET /cards/{id}/actions`

**Description:** List the Actions on a Card. See [Nested Resources](/cloud/trello/guides/rest-api/nested-resources/) for more information.

**Functions:**
- **Bash:** `trello_get_actions_on_card`
- **PowerShell:** `Invoke-TrelloGetActionsOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |
| page | number | query | No |

---

### Get Attachments on a Card

**Operation ID:** `get-cards-id-attachments`

**Endpoint:** `GET /cards/{id}/attachments`

**Description:** List the attachments on a card

**Functions:**
- **Bash:** `trello_get_attachments_on_card`
- **PowerShell:** `Invoke-TrelloGetAttachmentsOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |
| filter | string | query | No |

---

### Get an Attachment on a Card

**Operation ID:** `get-cards-id-attachments-idattachment`

**Endpoint:** `GET /cards/{id}/attachments/{idAttachment}`

**Description:** Get a specific Attachment on a Card.

**Functions:**
- **Bash:** `trello_get_attachment_on_card`
- **PowerShell:** `Invoke-TrelloGetAttachmentOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | array | query | No |

---

### Get the Board the Card is on

**Operation ID:** `get-cards-id-board`

**Endpoint:** `GET /cards/{id}/board`

**Description:** Get the board a card is on

**Functions:**
- **Bash:** `trello_get_board_card_is_on`
- **PowerShell:** `Invoke-TrelloGetBoardCardIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get checkItem on a Card

**Operation ID:** `get-cards-id-checkitem-idcheckitem`

**Endpoint:** `GET /cards/{id}/checkItem/{idCheckItem}`

**Description:** Get a specific checkItem on a card

**Functions:**
- **Bash:** `trello_get_checkitem_on_card`
- **PowerShell:** `Invoke-TrelloGetCheckitemOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get checkItems on a Card

**Operation ID:** `get-cards-id-checkitemstates`

**Endpoint:** `GET /cards/{id}/checkItemStates`

**Description:** Get the completed checklist items on a card

**Functions:**
- **Bash:** `trello_get_checkitems_on_card`
- **PowerShell:** `Invoke-TrelloGetCheckitemsOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get Checklists on a Card

**Operation ID:** `get-cards-id-checklists`

**Endpoint:** `GET /cards/{id}/checklists`

**Description:** Get the checklists on a card

**Functions:**
- **Bash:** `trello_get_checklists_on_card`
- **PowerShell:** `Invoke-TrelloGetChecklistsOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| checkItems | string | query | No |
| checkItem_fields | string | query | No |
| filter | string | query | No |
| fields | string | query | No |

---

### Get the List of a Card

**Operation ID:** `get-cards-id-list`

**Endpoint:** `GET /cards/{id}/list`

**Description:** Get the list a card is in

**Functions:**
- **Bash:** `trello_get_list_card`
- **PowerShell:** `Invoke-TrelloGetListCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Members of a Card

**Operation ID:** `get-cards-id-members`

**Endpoint:** `GET /cards/{id}/members`

**Description:** Get the members on a card

**Functions:**
- **Bash:** `trello_get_members_card`
- **PowerShell:** `Invoke-TrelloGetMembersCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get Members who have voted on a Card

**Operation ID:** `get-cards-id-membersvoted`

**Endpoint:** `GET /cards/{id}/membersVoted`

**Description:** Get the members who have voted on a card

**Functions:**
- **Bash:** `trello_get_members_who_have_voted_on_card`
- **PowerShell:** `Invoke-TrelloGetMembersWhoHaveVotedOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get pluginData on a Card

**Operation ID:** `get-cards-id-plugindata`

**Endpoint:** `GET /cards/{id}/pluginData`

**Description:** Get any shared pluginData on a card.

**Functions:**
- **Bash:** `trello_get_plugindata_on_card`
- **PowerShell:** `Invoke-TrelloGetPlugindataOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Stickers on a Card

**Operation ID:** `get-cards-id-stickers`

**Endpoint:** `GET /cards/{id}/stickers`

**Description:** Get the stickers on a card

**Functions:**
- **Bash:** `trello_get_stickers_on_card`
- **PowerShell:** `Invoke-TrelloGetStickersOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get a Sticker on a Card

**Operation ID:** `get-cards-id-stickers-idsticker`

**Endpoint:** `GET /cards/{id}/stickers/{idSticker}`

**Description:** Get a specific sticker on a card

**Functions:**
- **Bash:** `trello_get_sticker_on_card`
- **PowerShell:** `Invoke-TrelloGetStickerOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get a field on a Card

**Operation ID:** `get-cards-id-field`

**Endpoint:** `GET /cards/{id}/{field}`

**Description:** Get a specific property of a card

**Functions:**
- **Bash:** `trello_get_field_on_card`
- **PowerShell:** `Invoke-TrelloGetFieldOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Create a new Card

**Operation ID:** `post-cards`

**Endpoint:** `POST /cards`

**Description:** Create a new card. Query parameters may also be replaced with a JSON request body instead.

**Functions:**
- **Bash:** `trello_create_new_card`
- **PowerShell:** `Invoke-TrelloCreateNewCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| desc | string | query | No |
| pos | string | query | No |
| due | string | query | No |
| start | string | query | No |
| dueComplete | boolean | query | No |
| idList | string | query | Yes |
| idMembers | array | query | No |
| idLabels | array | query | No |
| urlSource | string | query | No |
| fileSource | string | query | No |
| mimeType | string | query | No |
| idCardSource | string | query | No |
| keepFromSource | string | query | No |
| address | string | query | No |
| locationName | string | query | No |
| coordinates | string | query | No |
| cardRole | string | query | No |

---

### Add a new comment to a Card

**Operation ID:** `post-cards-id-actions-comments`

**Endpoint:** `POST /cards/{id}/actions/comments`

**Description:** Add a new comment to a card

**Functions:**
- **Bash:** `trello_add_new_comment_to_card`
- **PowerShell:** `Invoke-TrelloAddNewCommentToCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| text | string | query | Yes |

---

### Create Attachment On Card

**Operation ID:** `post-cards-id-attachments`

**Endpoint:** `POST /cards/{id}/attachments`

**Description:** Create an Attachment to a Card. See https://glitch.com/~trello-attachments-api for code examples. You may need to remix the project in order to view it.

**Functions:**
- **Bash:** `trello_create_attachment_on_card`
- **PowerShell:** `Invoke-TrelloCreateAttachmentOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| file | string | query | No |
| mimeType | string | query | No |
| url | string | query | No |
| setCover | boolean | query | No |

---

### Create Checklist on a Card

**Operation ID:** `post-cards-id-checklists`

**Endpoint:** `POST /cards/{id}/checklists`

**Description:** Create a new checklist on a card

**Functions:**
- **Bash:** `trello_create_checklist_on_card`
- **PowerShell:** `Invoke-TrelloCreateChecklistOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| name | string | query | No |
| idChecklistSource | string | query | No |
| pos | string | query | No |

---

### Add a Label to a Card

**Operation ID:** `post-cards-id-idlabels`

**Endpoint:** `POST /cards/{id}/idLabels`

**Description:** Add a label to a card

**Functions:**
- **Bash:** `trello_add_label_to_card`
- **PowerShell:** `Invoke-TrelloAddLabelToCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | No |

---

### Add a Member to a Card

**Operation ID:** `post-cards-id-idmembers`

**Endpoint:** `POST /cards/{id}/idMembers`

**Description:** Add a member to a card

**Functions:**
- **Bash:** `trello_add_member_to_card`
- **PowerShell:** `Invoke-TrelloAddMemberToCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | No |

---

### Create a new Label on a Card

**Operation ID:** `post-cards-id-labels`

**Endpoint:** `POST /cards/{id}/labels`

**Description:** Create a new label for the board and add it to the given card.

**Functions:**
- **Bash:** `trello_create_new_label_on_card`
- **PowerShell:** `Invoke-TrelloCreateNewLabelOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| color | string | query | Yes |
| name | string | query | No |

---

### Mark a Card's Notifications as read

**Operation ID:** `post-cards-id-markassociatednotificationsread`

**Endpoint:** `POST /cards/{id}/markAssociatedNotificationsRead`

**Description:** Mark notifications about this card as read

**Functions:**
- **Bash:** `trello_mark_cards_notifications_as_read`
- **PowerShell:** `Invoke-TrelloMarkCardsNotificationsAsRead`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Add Member vote to Card

**Operation ID:** `cardsidmembersvoted-1`

**Endpoint:** `POST /cards/{id}/membersVoted`

**Description:** Vote on the card for a given member.

**Functions:**
- **Bash:** `trello_add_member_vote_to_card`
- **PowerShell:** `Invoke-TrelloAddMemberVoteToCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| value | string | query | Yes |

---

### Add a Sticker to a Card

**Operation ID:** `post-cards-id-stickers`

**Endpoint:** `POST /cards/{id}/stickers`

**Description:** Add a sticker to a card

**Functions:**
- **Bash:** `trello_add_sticker_to_card`
- **PowerShell:** `Invoke-TrelloAddStickerToCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| image | string | query | Yes |
| top | number | query | Yes |
| left | number | query | Yes |
| zIndex | integer | query | Yes |
| rotate | number | query | No |

---

## PUT Requests

### Update Checkitem on Checklist on Card

**Operation ID:** `put-cards-idcard-checklist-idchecklist-checkitem-idcheckitem`

**Endpoint:** `PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}`

**Description:** Update an item in a checklist on a card.

**Functions:**
- **Bash:** `trello_update_checkitem_on_checklist_on_card`
- **PowerShell:** `Invoke-TrelloUpdateCheckitemOnChecklistOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idCard | string | path | Yes |
| idCheckItem | string | path | Yes |
| pos | string | query | No |
| idChecklist | string | path | Yes |

---

### Update a Card

**Operation ID:** `put-cards-id`

**Endpoint:** `PUT /cards/{id}`

**Description:** Update a card. Query parameters may also be replaced with a JSON request body instead.

**Functions:**
- **Bash:** `trello_update_card`
- **PowerShell:** `Invoke-TrelloUpdateCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| desc | string | query | No |
| closed | boolean | query | No |
| idMembers | string | query | No |
| idAttachmentCover | string | query | No |
| idList | string | query | No |
| idLabels | string | query | No |
| idBoard | string | query | No |
| pos | string | query | No |
| due | string | query | No |
| start | string | query | No |
| dueComplete | boolean | query | No |
| subscribed | boolean | query | No |
| address | string | query | No |
| locationName | string | query | No |
| coordinates | string | query | No |
| cover | object | query | No |

---

### Update Comment Action on a Card

**Operation ID:** `put-cards-id-actions-idaction-comments`

**Endpoint:** `PUT /cards/{id}/actions/{idAction}/comments`

**Description:** Update an existing comment

**Functions:**
- **Bash:** `trello_update_comment_action_on_card`
- **PowerShell:** `Invoke-TrelloUpdateCommentActionOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| text | string | query | Yes |

---

### Update a checkItem on a Card

**Operation ID:** `put-cards-id-checkitem-idcheckitem`

**Endpoint:** `PUT /cards/{id}/checkItem/{idCheckItem}`

**Description:** Update an item in a checklist on a card.

**Functions:**
- **Bash:** `trello_update_checkitem_on_card`
- **PowerShell:** `Invoke-TrelloUpdateCheckitemOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| state | string | query | No |
| idChecklist | string | query | No |
| pos | string | query | No |
| due | string | query | No |
| dueReminder | number | query | No |
| idMember | string | query | No |

---

### Update a Sticker on a Card

**Operation ID:** `put-cards-id-stickers-idsticker`

**Endpoint:** `PUT /cards/{id}/stickers/{idSticker}`

**Description:** Update a sticker on a card

**Functions:**
- **Bash:** `trello_update_sticker_on_card`
- **PowerShell:** `Invoke-TrelloUpdateStickerOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| top | number | query | Yes |
| left | number | query | Yes |
| zIndex | integer | query | Yes |
| rotate | number | query | No |

---

## DELETE Requests

### Delete a Card

**Operation ID:** `delete-cards-id`

**Endpoint:** `DELETE /cards/{id}`

**Functions:**
- **Bash:** `trello_delete_card`
- **PowerShell:** `Invoke-TrelloDeleteCard`

---

### Delete a comment on a Card

**Operation ID:** `delete-cards-id-actions-id-comments`

**Endpoint:** `DELETE /cards/{id}/actions/{idAction}/comments`

**Description:** Delete a comment

**Functions:**
- **Bash:** `trello_delete_comment_on_card`
- **PowerShell:** `Invoke-TrelloDeleteCommentOnCard`

---

### Delete an Attachment on a Card

**Operation ID:** `deleted-cards-id-attachments-idattachment`

**Endpoint:** `DELETE /cards/{id}/attachments/{idAttachment}`

**Description:** Delete an Attachment

**Functions:**
- **Bash:** `trello_delete_attachment_on_card`
- **PowerShell:** `Invoke-TrelloDeleteAttachmentOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idAttachment | string | path | Yes |

---

### Delete checkItem on a Card

**Operation ID:** `delete-cards-id-checkitem-idcheckitem`

**Endpoint:** `DELETE /cards/{id}/checkItem/{idCheckItem}`

**Description:** Delete a checklist item

**Functions:**
- **Bash:** `trello_delete_checkitem_on_card`
- **PowerShell:** `Invoke-TrelloDeleteCheckitemOnCard`

---

### Delete a Checklist on a Card

**Operation ID:** `delete-cards-id-checklists-idchecklist`

**Endpoint:** `DELETE /cards/{id}/checklists/{idChecklist}`

**Description:** Delete a checklist from a card

**Functions:**
- **Bash:** `trello_delete_checklist_on_card`
- **PowerShell:** `Invoke-TrelloDeleteChecklistOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idChecklist | string | path | Yes |

---

### Remove a Label from a Card

**Operation ID:** `delete-cards-id-idlabels-idlabel`

**Endpoint:** `DELETE /cards/{id}/idLabels/{idLabel}`

**Description:** Remove a label from a card

**Functions:**
- **Bash:** `trello_remove_label_from_card`
- **PowerShell:** `Invoke-TrelloRemoveLabelFromCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idLabel | string | path | Yes |

---

### Remove a Member from a Card

**Operation ID:** `delete-id-idmembers-idmember`

**Endpoint:** `DELETE /cards/{id}/idMembers/{idMember}`

**Description:** Remove a member from a card

**Functions:**
- **Bash:** `trello_remove_member_from_card`
- **PowerShell:** `Invoke-TrelloRemoveMemberFromCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |

---

### Remove a Member's Vote on a Card

**Operation ID:** `delete-cards-id-membersvoted-idmember`

**Endpoint:** `DELETE /cards/{id}/membersVoted/{idMember}`

**Description:** Remove a member's vote from a card

**Functions:**
- **Bash:** `trello_remove_members_vote_on_card`
- **PowerShell:** `Invoke-TrelloRemoveMembersVoteOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |

---

### Delete a Sticker on a Card

**Operation ID:** `delete-cards-id-stickers-idsticker`

**Endpoint:** `DELETE /cards/{id}/stickers/{idSticker}`

**Description:** Remove a sticker from the card

**Functions:**
- **Bash:** `trello_delete_sticker_on_card`
- **PowerShell:** `Invoke-TrelloDeleteStickerOnCard`

---
