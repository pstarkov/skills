# Members Endpoints

Total: 33 endpoints

## GET Requests

### Get a Member

**Operation ID:** `get-members=id`

**Endpoint:** `GET /members/{id}`

**Description:** Get a member

**Functions:**
- **Bash:** `get_member`
- **PowerShell:** `Invoke-GetMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| actions | string | query | No |
| boards | string | query | No |
| boardBackgrounds | string | query | No |
| boardsInvited | string | query | No |
| boardsInvited_fields | string | query | No |
| boardStars | boolean | query | No |
| cards | string | query | No |
| customBoardBackgrounds | string | query | No |
| customEmoji | string | query | No |
| customStickers | string | query | No |
| fields | string | query | No |
| notifications | string | query | No |
| organizations | string | query | No |
| organization_fields | string | query | No |
| organization_paid_account | boolean | query | No |
| organizationsInvited | string | query | No |
| organizationsInvited_fields | string | query | No |
| paid_account | boolean | query | No |
| savedSearches | boolean | query | No |
| tokens | string | query | No |

---

### Get a Member's Actions

**Operation ID:** `get-members-id-actions`

**Endpoint:** `GET /members/{id}/actions`

**Description:** List the actions for a member

**Functions:**
- **Bash:** `get_members_actions`
- **PowerShell:** `Invoke-GetMembersActions`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |

---

### Get Member's custom Board backgrounds

**Operation ID:** `get-members-id-boardbackgrounds`

**Endpoint:** `GET /members/{id}/boardBackgrounds`

**Description:** Get a member's custom board backgrounds

**Functions:**
- **Bash:** `get_board_backgrounds`
- **PowerShell:** `Invoke-GetBoardBackgrounds`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |

---

### Get a boardBackground of a Member

**Operation ID:** `get-members-id-boardbackgrounds-idbackground`

**Endpoint:** `GET /members/{id}/boardBackgrounds/{idBackground}`

**Description:** Get a member's board background

**Functions:**
- **Bash:** `get_boardbackground_member`
- **PowerShell:** `Invoke-GetBoardbackgroundMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| fields | string | query | No |

---

### Get a Member's boardStars

**Operation ID:** `get-members-id-boardstars`

**Endpoint:** `GET /members/{id}/boardStars`

**Description:** List a member's board stars

**Functions:**
- **Bash:** `get_members_boardstars`
- **PowerShell:** `Invoke-GetMembersBoardstars`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get a boardStar of Member

**Operation ID:** `get-members-id-boardstars-idstar`

**Endpoint:** `GET /members/{id}/boardStars/{idStar}`

**Description:** Get a specific boardStar

**Functions:**
- **Bash:** `get_boardstar_member`
- **PowerShell:** `Invoke-GetBoardstarMember`

---

### Get Boards that Member belongs to

**Operation ID:** `get-members-id-boards`

**Endpoint:** `GET /members/{id}/boards`

**Description:** Lists the boards that the user is a member of.

**Functions:**
- **Bash:** `get_boards_that_member_belongs_to`
- **PowerShell:** `Invoke-GetBoardsThatMemberBelongsTo`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |
| fields | string | query | No |
| lists | string | query | No |
| organization | boolean | query | No |
| organization_fields | string | query | No |

---

### Get Boards the Member has been invited to

**Operation ID:** `get-members-id-boardsinvited`

**Endpoint:** `GET /members/{id}/boardsInvited`

**Description:** Get the boards the member has been invited to

**Functions:**
- **Bash:** `get_boards_member_has_been_invited_to`
- **PowerShell:** `Invoke-GetBoardsMemberHasBeenInvitedTo`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get Cards the Member is on

**Operation ID:** `get-members-id-cards`

**Endpoint:** `GET /members/{id}/cards`

**Description:** Gets the cards a member is on

**Functions:**
- **Bash:** `get_cards_member_is_on`
- **PowerShell:** `Invoke-GetCardsMemberIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |

---

### Get Member's Notifications

**Operation ID:** `get-members-id-notifications`

**Endpoint:** `GET /members/{id}/notifications`

**Description:** Get a member's notifications

**Functions:**
- **Bash:** `get_members_notifications`
- **PowerShell:** `Invoke-GetMembersNotifications`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| entities | boolean | query | No |
| display | boolean | query | No |
| filter | string | query | No |
| read_filter | string | query | No |
| fields | string | query | No |
| limit | integer | query | No |
| page | integer | query | No |
| before | string | query | No |
| since | string | query | No |
| memberCreator | boolean | query | No |
| memberCreator_fields | string | query | No |

---

### Get a Member's notification channel settings

**Operation ID:** `get-members-id-notificationChannelSettings`

**Endpoint:** `GET /members/{id}/notificationsChannelSettings`

**Description:** Get a member's notification channel settings

**Functions:**
- **Bash:** `get_members_notification_channel_settings`
- **PowerShell:** `Invoke-GetMembersNotificationChannelSettings`

---

### Get blocked notification keys of Member on this channel

**Operation ID:** `get-members-id-notificationChannelSettings-channel`

**Endpoint:** `GET /members/{id}/notificationsChannelSettings/{channel}`

**Description:** Get blocked notification keys of Member on a specific channel

**Functions:**
- **Bash:** `get_blocked_notification_keys_member_on_this_channel`
- **PowerShell:** `Invoke-GetBlockedNotificationKeysMemberOnThisChannel`

---

### Get Member's Organizations

**Operation ID:** `get-members-id-organizations`

**Endpoint:** `GET /members/{id}/organizations`

**Description:** Get a member's Workspaces

**Functions:**
- **Bash:** `get_members_organizations`
- **PowerShell:** `Invoke-GetMembersOrganizations`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |
| fields | string | query | No |
| paid_account | boolean | query | No |

---

### Get Organizations a Member has been invited to

**Operation ID:** `get-members-id-organizationsinvited`

**Endpoint:** `GET /members/{id}/organizationsInvited`

**Description:** Get a member's Workspaces they have been invited to

**Functions:**
- **Bash:** `get_organizations_member_has_been_invited_to`
- **PowerShell:** `Invoke-GetOrganizationsMemberHasBeenInvitedTo`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get Member's saved searched

**Operation ID:** `get-members-id-savedsearches`

**Endpoint:** `GET /members/{id}/savedSearches`

**Description:** List the saved searches of a Member

**Functions:**
- **Bash:** `get_members_saved_searched`
- **PowerShell:** `Invoke-GetMembersSavedSearched`

---

### Get a saved search

**Operation ID:** `get-members-id-savedsearches-idsearch`

**Endpoint:** `GET /members/{id}/savedSearches/{idSearch}`

**Functions:**
- **Bash:** `get_saved_search`
- **PowerShell:** `Invoke-GetSavedSearch`

---

### Get Member's Tokens

**Operation ID:** `get-members-id-tokens`

**Endpoint:** `GET /members/{id}/tokens`

**Description:** List a members app tokens

**Functions:**
- **Bash:** `get_members_tokens`
- **PowerShell:** `Invoke-GetMembersTokens`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| webhooks | boolean | query | No |

---

### Get a field on a Member

**Operation ID:** `get-members-id-field`

**Endpoint:** `GET /members/{id}/{field}`

**Description:** Get a particular property of a member

**Functions:**
- **Bash:** `get_field_on_member`
- **PowerShell:** `Invoke-GetFieldOnMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Create Avatar for Member

**Operation ID:** `membersidavatar`

**Endpoint:** `POST /members/{id}/avatar`

**Description:** Create a new avatar for a member

**Functions:**
- **Bash:** `create_avatar_for_member`
- **PowerShell:** `Invoke-CreateAvatarForMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| file | string | query | Yes |

---

### Upload new boardBackground for Member

**Operation ID:** `post-members-id-boardbackgrounds-1`

**Endpoint:** `POST /members/{id}/boardBackgrounds`

**Description:** Upload a new boardBackground

**Functions:**
- **Bash:** `upload_new_boardbackground_for_member`
- **PowerShell:** `Invoke-UploadNewBoardbackgroundForMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| file | string | query | Yes |

---

### Create Star for Board

**Operation ID:** `post-members-id-boardstars`

**Endpoint:** `POST /members/{id}/boardStars`

**Description:** Star a new board on behalf of a Member

**Functions:**
- **Bash:** `create_star_for_board`
- **PowerShell:** `Invoke-CreateStarForBoard`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idBoard | string | query | Yes |
| pos | string | query | Yes |

---

### Dismiss a message for Member

**Operation ID:** `post-members-id-onetimemessagesdismissed`

**Endpoint:** `POST /members/{id}/oneTimeMessagesDismissed`

**Description:** Dismiss a message

**Functions:**
- **Bash:** `dismiss_message_for_member`
- **PowerShell:** `Invoke-DismissMessageForMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | Yes |

---

### Create saved Search for Member

**Operation ID:** `post-members-id-savedsearches`

**Endpoint:** `POST /members/{id}/savedSearches`

**Description:** Create a saved search

**Functions:**
- **Bash:** `create_saved_search_for_member`
- **PowerShell:** `Invoke-CreateSavedSearchForMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | Yes |
| query | string | query | Yes |
| pos | string | query | Yes |

---

## PUT Requests

### Update a Member

**Operation ID:** `put-members-id`

**Endpoint:** `PUT /members/{id}`

**Functions:**
- **Bash:** `update_member`
- **PowerShell:** `Invoke-UpdateMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fullName | string | query | No |
| initials | string | query | No |
| username | string | query | No |
| bio | string | query | No |
| avatarSource | string | query | No |
| prefs/colorBlind | boolean | query | No |
| prefs/locale | string | query | No |
| prefs/minutesBetweenSummaries | integer | query | No |

---

### Update a Member's custom Board background

**Operation ID:** `put-members-id-boardbackgrounds-idbackground`

**Endpoint:** `PUT /members/{id}/boardBackgrounds/{idBackground}`

**Description:** Update a board background

**Functions:**
- **Bash:** `update_members_custom_board_background`
- **PowerShell:** `Invoke-UpdateMembersCustomBoardBackground`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| brightness | string | query | No |
| tile | boolean | query | No |

---

### Update the position of a boardStar of Member

**Operation ID:** `put-members-id-boardstars-idstar`

**Endpoint:** `PUT /members/{id}/boardStars/{idStar}`

**Description:** Update the position of a starred board

**Functions:**
- **Bash:** `update_position_boardstar_member`
- **PowerShell:** `Invoke-UpdatePositionBoardstarMember`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| pos | string | query | No |

---

### Update blocked notification keys of Member on a channel

**Operation ID:** `put-members-id-notificationChannelSettings-channel-blockedKeys`

**Endpoint:** `PUT /members/{id}/notificationsChannelSettings`

**Description:** Update blocked notification keys of Member on a specific channel

**Functions:**
- **Bash:** `update_blocked_notification_keys_member`
- **PowerShell:** `Invoke-UpdateBlockedNotificationKeysMember`

---

### Update blocked notification keys of Member on a channel

**Operation ID:** `put-members-id-notificationChannelSettings-channel-blockedKeys`

**Endpoint:** `PUT /members/{id}/notificationsChannelSettings/{channel}`

**Description:** Update blocked notification keys of Member on a specific channel

**Functions:**
- **Bash:** `update_blocked_notification_keys_member_channel`
- **PowerShell:** `Invoke-UpdateBlockedNotificationKeysMemberChannel`

---

### Update blocked notification keys of Member on a channel

**Operation ID:** `put-members-id-notificationChannelSettings-channel-blockedKeys`

**Endpoint:** `PUT /members/{id}/notificationsChannelSettings/{channel}/{blockedKeys}`

**Description:** Update blocked notification keys of Member on a specific channel

**Functions:**
- **Bash:** `update_blocked_notification_keys_member_on_channel`
- **PowerShell:** `Invoke-UpdateBlockedNotificationKeysMemberOnChannel`

---

### Update a saved search

**Operation ID:** `put-members-id-savedsearches-idsearch`

**Endpoint:** `PUT /members/{id}/savedSearches/{idSearch}`

**Functions:**
- **Bash:** `update_saved_search`
- **PowerShell:** `Invoke-UpdateSavedSearch`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| query | string | query | No |
| pos | string | query | No |

---

## DELETE Requests

### Delete a Member's custom Board background

**Operation ID:** `delete-members-id-boardbackgrounds-idbackground`

**Endpoint:** `DELETE /members/{id}/boardBackgrounds/{idBackground}`

**Description:** Delete a board background

**Functions:**
- **Bash:** `delete_members_custom_board_background`
- **PowerShell:** `Invoke-DeleteMembersCustomBoardBackground`

---

### Delete Star for Board

**Operation ID:** `delete-members-id-boardstars-idstar`

**Endpoint:** `DELETE /members/{id}/boardStars/{idStar}`

**Description:** Unstar a board

**Functions:**
- **Bash:** `delete_star_for_board`
- **PowerShell:** `Invoke-DeleteStarForBoard`

---

### Delete a saved search

**Operation ID:** `delete-members-id-savedsearches-idsearch`

**Endpoint:** `DELETE /members/{id}/savedSearches/{idSearch}`

**Functions:**
- **Bash:** `delete_saved_search`
- **PowerShell:** `Invoke-DeleteSavedSearch`

---
