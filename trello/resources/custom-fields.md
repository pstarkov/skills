# Custom Fields Endpoints

Total: 24 endpoints

## GET Requests

### Get Custom Fields for Board

**Operation ID:** `get-boards-id-customfields`

**Endpoint:** `GET /boards/{id}/customFields`

**Description:** Get the Custom Field Definitions that exist on a board.

**Functions:**
- **Bash:** `trello_get_custom_fields_for_board`
- **PowerShell:** `Invoke-TrelloGetCustomFieldsForBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Custom Field Items for a Card

**Operation ID:** `get-cards-id-customfielditems`

**Endpoint:** `GET /cards/{id}/customFieldItems`

**Description:** Get the custom field items for a card.

**Functions:**
- **Bash:** `trello_get_custom_field_items_for_card`
- **PowerShell:** `Invoke-TrelloGetCustomFieldItemsForCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get a Custom Field

**Operation ID:** `get-customfields-id`

**Endpoint:** `GET /customFields/{id}`

**Functions:**
- **Bash:** `trello_get_custom_field`
- **PowerShell:** `Invoke-TrelloGetCustomField`

---

### Get Options of Custom Field drop down

**Operation ID:** `post-customfields-id-options`

**Endpoint:** `GET /customFields/{id}/options`

**Description:** Get the options of a drop down Custom Field

**Functions:**
- **Bash:** `trello_get_options_custom_field_drop_down`
- **PowerShell:** `Invoke-TrelloGetOptionsCustomFieldDropDown`

---

### Get Option of Custom Field dropdown

**Operation ID:** `get-customfields-options-idcustomfieldoption`

**Endpoint:** `GET /customFields/{id}/options/{idCustomFieldOption}`

**Description:** Retrieve a specific, existing Option on a given dropdown-type Custom Field

**Functions:**
- **Bash:** `trello_get_option_custom_field_dropdown`
- **PowerShell:** `Invoke-TrelloGetOptionCustomFieldDropdown`

---

### Get a Member's custom Board Backgrounds

**Operation ID:** `get-members-id-customboardbackgrounds`

**Endpoint:** `GET /members/{id}/customBoardBackgrounds`

**Description:** Get a member's custom board backgrounds

**Functions:**
- **Bash:** `trello_get_custom_board_backgrounds`
- **PowerShell:** `Invoke-TrelloGetCustomBoardBackgrounds`

---

### Get custom Board Background of Member

**Operation ID:** `get-members-id-customboardbackgrounds-idbackground`

**Endpoint:** `GET /members/{id}/customBoardBackgrounds/{idBackground}`

**Description:** Get a specific custom board background

**Functions:**
- **Bash:** `trello_get_custom_board_background_member`
- **PowerShell:** `Invoke-TrelloGetCustomBoardBackgroundMember`

---

### Get a Member's customEmojis

**Operation ID:** `get-members-id-customemoji`

**Endpoint:** `GET /members/{id}/customEmoji`

**Description:** Get a Member's uploaded custom Emojis

**Functions:**
- **Bash:** `trello_get_members_customemojis`
- **PowerShell:** `Invoke-TrelloGetMembersCustomemojis`

---

### Get a Member's custom Emoji

**Operation ID:** `membersidcustomemojiidemoji`

**Endpoint:** `GET /members/{id}/customEmoji/{idEmoji}`

**Functions:**
- **Bash:** `trello_get_members_custom_emoji`
- **PowerShell:** `Invoke-TrelloGetMembersCustomEmoji`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idEmoji | string | path | Yes |
| fields | string | query | No |

---

### Get Member's custom Stickers

**Operation ID:** `get-members-id-customstickers`

**Endpoint:** `GET /members/{id}/customStickers`

**Description:** Get a Member's uploaded stickers

**Functions:**
- **Bash:** `trello_get_members_custom_stickers`
- **PowerShell:** `Invoke-TrelloGetMembersCustomStickers`

---

### Get a Member's custom Sticker

**Operation ID:** `get-members-id-customstickers-idsticker`

**Endpoint:** `GET /members/{id}/customStickers/{idSticker}`

**Functions:**
- **Bash:** `trello_get_members_custom_sticker`
- **PowerShell:** `Invoke-TrelloGetMembersCustomSticker`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

## POST Requests

### Create a new Custom Field on a Board

**Operation ID:** `post-customfields`

**Endpoint:** `POST /customFields`

**Description:** Create a new Custom Field on a board.

**Functions:**
- **Bash:** `trello_create_new_custom_field_on_board`
- **PowerShell:** `Invoke-TrelloCreateNewCustomFieldOnBoard`

---

### Add Option to Custom Field dropdown

**Operation ID:** `get-customfields-id-options`

**Endpoint:** `POST /customFields/{id}/options`

**Description:** Add an option to a dropdown Custom Field

**Functions:**
- **Bash:** `trello_add_option_to_custom_field_dropdown`
- **PowerShell:** `Invoke-TrelloAddOptionToCustomFieldDropdown`

---

### Create a new custom Board Background

**Operation ID:** `membersidcustomboardbackgrounds-1`

**Endpoint:** `POST /members/{id}/customBoardBackgrounds`

**Description:** Upload a new custom board background

**Functions:**
- **Bash:** `trello_create_new_custom_board_background`
- **PowerShell:** `Invoke-TrelloCreateNewCustomBoardBackground`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| file | string | query | Yes |

---

### Create custom Emoji for Member

**Operation ID:** `post-members-id-customemoji`

**Endpoint:** `POST /members/{id}/customEmoji`

**Description:** Create a new custom Emoji

**Functions:**
- **Bash:** `trello_create_custom_emoji_for_member`
- **PowerShell:** `Invoke-TrelloCreateCustomEmojiForMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| file | string | query | Yes |
| name | string | query | Yes |

---

### Create custom Sticker for Member

**Operation ID:** `post-members-id-customstickers`

**Endpoint:** `POST /members/{id}/customStickers`

**Description:** Upload a new custom sticker

**Functions:**
- **Bash:** `trello_create_custom_sticker_for_member`
- **PowerShell:** `Invoke-TrelloCreateCustomStickerForMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| file | string | query | Yes |

---

## PUT Requests

### Update Custom Field item on Card

**Operation ID:** `put-cards-idcard-customfield-idcustomfield-item`

**Endpoint:** `PUT /cards/{idCard}/customField/{idCustomField}/item`

**Description:** Setting, updating, and removing the value for a Custom Field on a card. For more details on updating custom fields check out the [Getting Started With Custom Fields](/cloud/trello/guides/rest-api/gett...

**Functions:**
- **Bash:** `trello_update_custom_field_item_on_card`
- **PowerShell:** `Invoke-TrelloUpdateCustomFieldItemOnCard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idCard | string | path | Yes |
| idCustomField | string | path | Yes |

---

### Update Multiple Custom Field items on Card

**Operation ID:** `put-cards-idcard-customfields`

**Endpoint:** `PUT /cards/{idCard}/customFields`

**Description:** Setting, updating, and removing the values for multiple Custom Fields on a card. For more details on updating custom fields check out the [Getting Started With Custom Fields](/cloud/trello/guides/rest...

**Functions:**
- **Bash:** `trello_update_multiple_custom_field_items_on_card`
- **PowerShell:** `Invoke-TrelloUpdateMultipleCustomFieldItemsOnCard`

---

### Update a Custom Field definition

**Operation ID:** `put-customfields-id`

**Endpoint:** `PUT /customFields/{id}`

**Description:** Update a Custom Field definition.

**Functions:**
- **Bash:** `trello_update_custom_field_definition`
- **PowerShell:** `Invoke-TrelloUpdateCustomFieldDefinition`

---

### Update custom Board Background of Member

**Operation ID:** `put-members-id-customboardbackgrounds-idbackground`

**Endpoint:** `PUT /members/{id}/customBoardBackgrounds/{idBackground}`

**Description:** Update a specific custom board background

**Functions:**
- **Bash:** `trello_update_custom_board_background_member`
- **PowerShell:** `Invoke-TrelloUpdateCustomBoardBackgroundMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| brightness | string | query | No |
| tile | boolean | query | No |

---

## DELETE Requests

### Delete a Custom Field definition

**Operation ID:** `delete-customfields-id`

**Endpoint:** `DELETE /customFields/{id}`

**Description:** Delete a Custom Field from a board.

**Functions:**
- **Bash:** `trello_delete_custom_field_definition`
- **PowerShell:** `Invoke-TrelloDeleteCustomFieldDefinition`

---

### Delete Option of Custom Field dropdown

**Operation ID:** `delete-customfields-options-idcustomfieldoption`

**Endpoint:** `DELETE /customFields/{id}/options/{idCustomFieldOption}`

**Description:** Delete an option from a Custom Field dropdown.

**Functions:**
- **Bash:** `trello_delete_option_custom_field_dropdown`
- **PowerShell:** `Invoke-TrelloDeleteOptionCustomFieldDropdown`

---

### Delete custom Board Background of Member

**Operation ID:** `delete-members-id-customboardbackgrounds-idbackground`

**Endpoint:** `DELETE /members/{id}/customBoardBackgrounds/{idBackground}`

**Description:** Delete a specific custom board background

**Functions:**
- **Bash:** `trello_delete_custom_board_background_member`
- **PowerShell:** `Invoke-TrelloDeleteCustomBoardBackgroundMember`

---

### Delete a Member's custom Sticker

**Operation ID:** `delete-members-id-customstickers-idsticker`

**Endpoint:** `DELETE /members/{id}/customStickers/{idSticker}`

**Functions:**
- **Bash:** `trello_delete_members_custom_sticker`
- **PowerShell:** `Invoke-TrelloDeleteMembersCustomSticker`

---
