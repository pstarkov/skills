# Boards Endpoints

Total: 35 endpoints

## GET Requests

### Get Actions of a Board

**Operation ID:** `get-boards-id-actions`

**Endpoint:** `GET /boards/{boardId}/actions`

**Description:** Get all of the actions of a Board. See [Nested Resources](/cloud/trello/guides/rest-api/nested-resources/) for more information.

**Functions:**
- **Bash:** `get_actions_board`
- **PowerShell:** `Invoke-GetActionsBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| boardId | string | path | Yes |
| fields | string | query | No |
| filter | string | query | No |
| format | string | query | No |
| idModels | string | query | No |
| limit | number | query | No |
| member | boolean | query | No |
| member_fields | string | query | No |
| memberCreator | boolean | query | No |
| memberCreator_fields | string | query | No |
| page | number | query | No |
| reactions | boolean | query | No |
| before | string | query | No |
| since | string | query | No |

---

### Get boardStars on a Board

**Operation ID:** `get-boards-id-boardstars`

**Endpoint:** `GET /boards/{boardId}/boardStars`

**Functions:**
- **Bash:** `get_boardstars_on_board`
- **PowerShell:** `Invoke-GetBoardstarsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| boardId | string | path | Yes |
| filter | string | query | No |

---

### Get a Board

**Operation ID:** `get-boards-id`

**Endpoint:** `GET /boards/{id}`

**Description:** Request a single board.

**Functions:**
- **Bash:** `get_board`
- **PowerShell:** `Invoke-GetBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| actions | string | query | No |
| boardStars | string | query | No |
| cards | string | query | No |
| card_pluginData | boolean | query | No |
| checklists | string | query | No |
| customFields | boolean | query | No |
| fields | string | query | No |
| labels | string | query | No |
| lists | string | query | No |
| members | string | query | No |
| memberships | string | query | No |
| pluginData | boolean | query | No |
| organization | boolean | query | No |
| organization_pluginData | boolean | query | No |
| myPrefs | boolean | query | No |
| tags | boolean | query | No |

---

### Get Enabled Power-Ups on Board

**Operation ID:** `get-boards-id-boardplugins`

**Endpoint:** `GET /boards/{id}/boardPlugins`

**Description:** Get the enabled Power-Ups on a board

**Functions:**
- **Bash:** `get_enabled_powerups_on_board`
- **PowerShell:** `Invoke-GetEnabledPowerupsOnBoard`

---

### Get Cards on a Board

**Operation ID:** `get-boards-id-cards`

**Endpoint:** `GET /boards/{id}/cards`

**Description:** Get all of the open Cards on a Board. See [Nested Resources](/cloud/trello/guides/rest-api/nested-resources/) for more information.

**Functions:**
- **Bash:** `get_cards_on_board`
- **PowerShell:** `Invoke-GetCardsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get filtered Cards on a Board

**Operation ID:** `get-boards-id-cards-filter`

**Endpoint:** `GET /boards/{id}/cards/{filter}`

**Description:** Get the Cards on a Board that match a given filter. See [Nested Resources](/cloud/trello/guides/rest-api/nested-resources/) for more information.

**Functions:**
- **Bash:** `get_filtered_cards_on_board`
- **PowerShell:** `Invoke-GetFilteredCardsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | path | Yes |

---

### Get Checklists on a Board

**Operation ID:** `boards-id-checklists`

**Endpoint:** `GET /boards/{id}/checklists`

**Description:** Get all of the checklists on a Board.

**Functions:**
- **Bash:** `get_checklists_on_board`
- **PowerShell:** `Invoke-GetChecklistsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Labels on a Board

**Operation ID:** `get-boards-id-labels`

**Endpoint:** `GET /boards/{id}/labels`

**Description:** Get all of the Labels on a Board.

**Functions:**
- **Bash:** `get_labels_on_board`
- **PowerShell:** `Invoke-GetLabelsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |
| limit | integer | query | No |

---

### Get Lists on a Board

**Operation ID:** `get-boards-id-lists`

**Endpoint:** `GET /boards/{id}/lists`

**Description:** Get the Lists on a Board

**Functions:**
- **Bash:** `get_lists_on_board`
- **PowerShell:** `Invoke-GetListsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| cards | string | query | No |
| card_fields | string | query | No |
| filter | string | query | No |
| fields | string | query | No |

---

### Get filtered Lists on a Board

**Operation ID:** `get-boards-id-lists-filter`

**Endpoint:** `GET /boards/{id}/lists/{filter}`

**Functions:**
- **Bash:** `get_filtered_lists_on_board`
- **PowerShell:** `Invoke-GetFilteredListsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | path | Yes |

---

### Get the Members of a Board

**Operation ID:** `get-boards-id-members`

**Endpoint:** `GET /boards/{id}/members`

**Description:** Get the Members for a board

**Functions:**
- **Bash:** `get_members_board`
- **PowerShell:** `Invoke-GetMembersBoard`

---

### Get Memberships of a Board

**Operation ID:** `get-boards-id-memberships`

**Endpoint:** `GET /boards/{id}/memberships`

**Description:** Get information about the memberships users have to the board.

**Functions:**
- **Bash:** `get_memberships_board`
- **PowerShell:** `Invoke-GetMembershipsBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |
| activity | boolean | query | No |
| orgMemberType | boolean | query | No |
| member | boolean | query | No |
| member_fields | string | query | No |

---

### Get Power-Ups on a Board

**Operation ID:** `get-board-id-plugins`

**Endpoint:** `GET /boards/{id}/plugins`

**Description:** List the Power-Ups on a board

**Functions:**
- **Bash:** `get_powerups_on_board`
- **PowerShell:** `Invoke-GetPowerupsOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |

---

### Get a field on a Board

**Operation ID:** `get-boards-id-field`

**Endpoint:** `GET /boards/{id}/{field}`

**Description:** Get a single, specific field on a board

**Functions:**
- **Bash:** `get_field_on_board`
- **PowerShell:** `Invoke-GetFieldOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Create a Board

**Operation ID:** `post-boards`

**Endpoint:** `POST /boards/`

**Description:** Create a new board.

**Functions:**
- **Bash:** `create_board`
- **PowerShell:** `Invoke-CreateBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | Yes |
| defaultLabels | boolean | query | No |
| defaultLists | boolean | query | No |
| desc | string | query | No |
| idOrganization | string | query | No |
| idBoardSource | string | query | No |
| keepFromSource | string | query | No |
| powerUps | string | query | No |
| prefs_permissionLevel | string | query | No |
| prefs_voting | string | query | No |
| prefs_comments | string | query | No |
| prefs_invitations | string | query | No |
| prefs_selfJoin | boolean | query | No |
| prefs_cardCovers | boolean | query | No |
| prefs_background | string | query | No |
| prefs_cardAging | string | query | No |

---

### Enable a Power-Up on a Board

**Operation ID:** `post-boards-id-boardplugins`

**Endpoint:** `POST /boards/{id}/boardPlugins`

**Functions:**
- **Bash:** `enable_powerup_on_board`
- **PowerShell:** `Invoke-EnablePowerupOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idPlugin | string | query | No |

---

### Create a calendarKey for a Board

**Operation ID:** `post-boards-id-calendarkey-generate`

**Endpoint:** `POST /boards/{id}/calendarKey/generate`

**Description:** Create a new board.

**Functions:**
- **Bash:** `create_calendarkey_for_board`
- **PowerShell:** `Invoke-CreateCalendarkeyForBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Create a emailKey for a Board

**Operation ID:** `post-boards-id-emailkey-generate`

**Endpoint:** `POST /boards/{id}/emailKey/generate`

**Functions:**
- **Bash:** `create_emailkey_for_board`
- **PowerShell:** `Invoke-CreateEmailkeyForBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Create a Tag for a Board

**Operation ID:** `post-boards-id-idtags`

**Endpoint:** `POST /boards/{id}/idTags`

**Functions:**
- **Bash:** `create_tag_for_board`
- **PowerShell:** `Invoke-CreateTagForBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | Yes |

---

### Create a Label on a Board

**Operation ID:** `post-boards-id-labels`

**Endpoint:** `POST /boards/{id}/labels`

**Description:** Create a new Label on a Board.

**Functions:**
- **Bash:** `create_label_on_board`
- **PowerShell:** `Invoke-CreateLabelOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| name | string | query | Yes |
| color | string | query | Yes |

---

### Create a List on a Board

**Operation ID:** `post-boards-id-lists`

**Endpoint:** `POST /boards/{id}/lists`

**Description:** Create a new List on a Board.

**Functions:**
- **Bash:** `create_list_on_board`
- **PowerShell:** `Invoke-CreateListOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | Yes |
| pos | string | query | No |

---

### Mark Board as viewed

**Operation ID:** `post-boards-id-markedasviewed`

**Endpoint:** `POST /boards/{id}/markedAsViewed`

**Functions:**
- **Bash:** `mark_board_as_viewed`
- **PowerShell:** `Invoke-MarkBoardAsViewed`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

## PUT Requests

### Update a Board

**Operation ID:** `put-boards-id`

**Endpoint:** `PUT /boards/{id}`

**Description:** Update an existing board by id

**Functions:**
- **Bash:** `update_board`
- **PowerShell:** `Invoke-UpdateBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| desc | string | query | No |
| closed | boolean | query | No |
| subscribed | string | query | No |
| idOrganization | string | query | No |
| prefs/permissionLevel | string | query | No |
| prefs/selfJoin | boolean | query | No |
| prefs/cardCovers | boolean | query | No |
| prefs/hideVotes | boolean | query | No |
| prefs/invitations | string | query | No |
| prefs/voting | string | query | No |
| prefs/comments | string | query | No |
| prefs/background | string | query | No |
| prefs/cardAging | string | query | No |
| prefs/calendarFeedEnabled | boolean | query | No |

---

### Invite Member to Board via email

**Operation ID:** `put-boards-id-members`

**Endpoint:** `PUT /boards/{id}/members`

**Description:** Invite a Member to a Board via their email address.

**Functions:**
- **Bash:** `invite_member_to_board_via_email`
- **PowerShell:** `Invoke-InviteMemberToBoardViaEmail`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| email | string | query | Yes |
| type | string | query | No |

---

### Add a Member to a Board

**Operation ID:** `put-boards-id-members-idmember`

**Endpoint:** `PUT /boards/{id}/members/{idMember}`

**Description:** Add a member to the board.

**Functions:**
- **Bash:** `add_member_to_board`
- **PowerShell:** `Invoke-AddMemberToBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| type | string | query | Yes |
| allowBillableGuest | boolean | query | No |

---

### Update Membership of Member on a Board

**Operation ID:** `put-boards-id-memberships-idmembership`

**Endpoint:** `PUT /boards/{id}/memberships/{idMembership}`

**Description:** Update an existing board by id

**Functions:**
- **Bash:** `update_membership_member_on_board`
- **PowerShell:** `Invoke-UpdateMembershipMemberOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMembership | string | path | Yes |
| type | string | query | Yes |
| member_fields | string | query | No |

---

### Update emailPosition Pref on a Board

**Operation ID:** `put-boards-id-myprefs-emailposition`

**Endpoint:** `PUT /boards/{id}/myPrefs/emailPosition`

**Functions:**
- **Bash:** `update_emailposition_pref_on_board`
- **PowerShell:** `Invoke-UpdateEmailpositionPrefOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | Yes |

---

### Update idEmailList Pref on a Board

**Operation ID:** `put-boards-id-myprefs-idemaillist`

**Endpoint:** `PUT /boards/{id}/myPrefs/idEmailList`

**Description:** Change the default list that email-to-board cards are created in.

**Functions:**
- **Bash:** `update_idemaillist_pref_on_board`
- **PowerShell:** `Invoke-UpdateIdemaillistPrefOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | Yes |

---

### Update showSidebar Pref on a Board

**Operation ID:** `put-boards-id-myPrefs-showsidebar`

**Endpoint:** `PUT /boards/{id}/myPrefs/showSidebar`

**Functions:**
- **Bash:** `update_showsidebar_pref_on_board`
- **PowerShell:** `Invoke-UpdateShowsidebarPrefOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | boolean | query | Yes |

---

### Update showSidebarActivity Pref on a Board

**Operation ID:** `put-boards-id-myPrefs-showsidebaractivity`

**Endpoint:** `PUT /boards/{id}/myPrefs/showSidebarActivity`

**Functions:**
- **Bash:** `update_showsidebaractivity_pref_on_board`
- **PowerShell:** `Invoke-UpdateShowsidebaractivityPrefOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | boolean | query | Yes |

---

### Update showSidebarBoardActions Pref on a Board

**Operation ID:** `put-boards-id-myPrefs-showsidebarboardactions`

**Endpoint:** `PUT /boards/{id}/myPrefs/showSidebarBoardActions`

**Functions:**
- **Bash:** `update_showsidebarboardactions_pref_on_board`
- **PowerShell:** `Invoke-UpdateShowsidebarboardactionsPrefOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | boolean | query | Yes |

---

### Update showSidebarMembers Pref on a Board

**Operation ID:** `put-boards-id-myPrefs-showsidebarmembers`

**Endpoint:** `PUT /boards/{id}/myPrefs/showSidebarMembers`

**Functions:**
- **Bash:** `update_showsidebarmembers_pref_on_board`
- **PowerShell:** `Invoke-UpdateShowsidebarmembersPrefOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | boolean | query | Yes |

---

## DELETE Requests

### Delete a Board

**Operation ID:** `delete-boards-id`

**Endpoint:** `DELETE /boards/{id}`

**Description:** Delete a board.

**Functions:**
- **Bash:** `delete_board`
- **PowerShell:** `Invoke-DeleteBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Disable a Power-Up on a Board

**Operation ID:** `delete-boards-id-boardplugins`

**Endpoint:** `DELETE /boards/{id}/boardPlugins/{idPlugin}`

**Description:** Disable a Power-Up on a board

**Functions:**
- **Bash:** `disable_powerup_on_board`
- **PowerShell:** `Invoke-DisablePowerupOnBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idPlugin | string | path | Yes |

---

### Remove Member from Board

**Operation ID:** `boardsidmembersidmember`

**Endpoint:** `DELETE /boards/{id}/members/{idMember}`

**Functions:**
- **Bash:** `remove_member_from_board`
- **PowerShell:** `Invoke-RemoveMemberFromBoard`

---
