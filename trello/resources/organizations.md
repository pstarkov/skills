# Organizations Endpoints

Total: 26 endpoints

## GET Requests

### Get an Organization

**Operation ID:** `get-organizations-id`

**Endpoint:** `GET /organizations/{id}`

**Functions:**
- **Bash:** `trello_get_organization`
- **PowerShell:** `Invoke-TrelloGetOrganization`

---

### Get Actions for Organization

**Operation ID:** `get-organizations-id-actions`

**Endpoint:** `GET /organizations/{id}/actions`

**Description:** List the actions on a Workspace

**Functions:**
- **Bash:** `trello_get_actions_for_organization`
- **PowerShell:** `Invoke-TrelloGetActionsForOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Boards in an Organization

**Operation ID:** `get-organizations-id-boards`

**Endpoint:** `GET /organizations/{id}/boards`

**Description:** List the boards in a Workspace

**Functions:**
- **Bash:** `trello_get_boards_in_organization`
- **PowerShell:** `Invoke-TrelloGetBoardsInOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |
| fields | string | query | No |

---

### Retrieve Organization's Exports

**Operation ID:** `get-organizations-id-exports`

**Endpoint:** `GET /organizations/{id}/exports`

**Description:** Retrieve the exports that exist for the given organization

**Functions:**
- **Bash:** `trello_retrieve_organizations_exports`
- **PowerShell:** `Invoke-TrelloRetrieveOrganizationsExports`

---

### Get the Members of an Organization

**Operation ID:** `get-organizations-id-members`

**Endpoint:** `GET /organizations/{id}/members`

**Description:** List the members in a Workspace

**Functions:**
- **Bash:** `trello_get_members_organization`
- **PowerShell:** `Invoke-TrelloGetMembersOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Memberships of an Organization

**Operation ID:** `get-organizations-id-memberships`

**Endpoint:** `GET /organizations/{id}/memberships`

**Description:** List the memberships of a Workspace

**Functions:**
- **Bash:** `trello_get_memberships_organization`
- **PowerShell:** `Invoke-TrelloGetMembershipsOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| filter | string | query | No |
| member | boolean | query | No |

---

### Get a Membership of an Organization

**Operation ID:** `get-organizations-id-memberships-idmembership`

**Endpoint:** `GET /organizations/{id}/memberships/{idMembership}`

**Description:** Get a single Membership for an Organization

**Functions:**
- **Bash:** `trello_get_membership_organization`
- **PowerShell:** `Invoke-TrelloGetMembershipOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMembership | string | path | Yes |
| member | boolean | query | No |

---

### Get Organizations new billable guests

**Operation ID:** `get-organizations-id-newbillableguests-idboard`

**Endpoint:** `GET /organizations/{id}/newBillableGuests/{idBoard}`

**Description:** Used to check whether the given board has new billable guests on it.

**Functions:**
- **Bash:** `trello_get_organizations_new_billable_guests`
- **PowerShell:** `Invoke-TrelloGetOrganizationsNewBillableGuests`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idBoard | string | path | Yes |

---

### Get the pluginData Scoped to Organization

**Operation ID:** `get-organizations-id-plugindata`

**Endpoint:** `GET /organizations/{id}/pluginData`

**Description:** Get organization scoped pluginData on this Workspace

**Functions:**
- **Bash:** `trello_get_plugindata_scoped_to_organization`
- **PowerShell:** `Invoke-TrelloGetPlugindataScopedToOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Tags of an Organization

**Operation ID:** `get-organizations-id-tags`

**Endpoint:** `GET /organizations/{id}/tags`

**Description:** List the organization's collections

**Functions:**
- **Bash:** `trello_get_tags_organization`
- **PowerShell:** `Invoke-TrelloGetTagsOrganization`

---

### Get field on Organization

**Operation ID:** `get-organizations-id-field`

**Endpoint:** `GET /organizations/{id}/{field}`

**Functions:**
- **Bash:** `trello_get_field_on_organization`
- **PowerShell:** `Invoke-TrelloGetFieldOnOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Create a new Organization

**Operation ID:** `post-organizations`

**Endpoint:** `POST /organizations`

**Description:** Create a new Workspace

**Functions:**
- **Bash:** `trello_create_new_organization`
- **PowerShell:** `Invoke-TrelloCreateNewOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| displayName | string | query | Yes |
| desc | string | query | No |
| name | string | query | No |
| website | string | query | No |

---

### Create Export for Organizations

**Operation ID:** `post-organizations-id-exports`

**Endpoint:** `POST /organizations/{id}/exports`

**Description:** Kick off CSV export for an organization

**Functions:**
- **Bash:** `trello_create_export_for_organizations`
- **PowerShell:** `Invoke-TrelloCreateExportForOrganizations`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| attachments | boolean | query | No |

---

### Update logo for an Organization

**Operation ID:** `post-organizations-id-logo`

**Endpoint:** `POST /organizations/{id}/logo`

**Description:** Set the logo image for a Workspace

**Functions:**
- **Bash:** `trello_update_logo_for_organization`
- **PowerShell:** `Invoke-TrelloUpdateLogoForOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| file | string | query | No |

---

### Create a Tag in Organization

**Operation ID:** `post-organizations-id-tags`

**Endpoint:** `POST /organizations/{id}/tags`

**Description:** Create a Tag in an Organization

**Functions:**
- **Bash:** `trello_create_tag_in_organization`
- **PowerShell:** `Invoke-TrelloCreateTagInOrganization`

---

## PUT Requests

### Update an Organization

**Operation ID:** `put-organizations-id`

**Endpoint:** `PUT /organizations/{id}`

**Description:** Update an organization

**Functions:**
- **Bash:** `trello_update_organization`
- **PowerShell:** `Invoke-TrelloUpdateOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| name | string | query | No |
| displayName | string | query | No |
| desc | string | query | No |
| website | string | query | No |
| prefs/associatedDomain | string | query | No |
| prefs/externalMembersDisabled | boolean | query | No |
| prefs/googleAppsVersion | integer | query | No |
| prefs/boardVisibilityRestrict/org | string | query | No |
| prefs/boardVisibilityRestrict/private | string | query | No |
| prefs/boardVisibilityRestrict/public | string | query | No |
| prefs/orgInviteRestrict | string | query | No |
| prefs/permissionLevel | string | query | No |

---

### Update an Organization's Members

**Operation ID:** `put-organizations-id-members`

**Endpoint:** `PUT /organizations/{id}/members`

**Functions:**
- **Bash:** `trello_update_organizations_members`
- **PowerShell:** `Invoke-TrelloUpdateOrganizationsMembers`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| email | string | query | Yes |
| fullName | string | query | Yes |
| type | string | query | No |

---

### Update a Member of an Organization

**Operation ID:** `put-organizations-id-members-idmember`

**Endpoint:** `PUT /organizations/{id}/members/{idMember}`

**Description:** Add a member to a Workspace or update their member type.

**Functions:**
- **Bash:** `trello_update_member_organization`
- **PowerShell:** `Invoke-TrelloUpdateMemberOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |
| type | string | query | Yes |

---

### Deactivate or reactivate a member of an Organization

**Operation ID:** `put-organizations-id-members-idmember-deactivated`

**Endpoint:** `PUT /organizations/{id}/members/{idMember}/deactivated`

**Description:** Deactivate or reactivate a member of a Workspace

**Functions:**
- **Bash:** `trello_deactivate_or_reactivate_member_organization`
- **PowerShell:** `Invoke-TrelloDeactivateOrReactivateMemberOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |
| value | boolean | query | Yes |

---

## DELETE Requests

### Delete an Organization

**Operation ID:** `delete-organizations-id`

**Endpoint:** `DELETE /organizations/{id}`

**Functions:**
- **Bash:** `trello_delete_organization`
- **PowerShell:** `Invoke-TrelloDeleteOrganization`

---

### Delete Logo for Organization

**Operation ID:** `delete-organizations-id-logo`

**Endpoint:** `DELETE /organizations/{id}/logo`

**Description:** Delete a the logo from a Workspace

**Functions:**
- **Bash:** `trello_delete_logo_for_organization`
- **PowerShell:** `Invoke-TrelloDeleteLogoForOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Remove a Member from an Organization

**Operation ID:** `delete-organizations-id-members`

**Endpoint:** `DELETE /organizations/{id}/members/{idMember}`

**Description:** Remove a member from a Workspace

**Functions:**
- **Bash:** `trello_remove_member_from_organization`
- **PowerShell:** `Invoke-TrelloRemoveMemberFromOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |

---

### Remove a Member from an Organization and all Organization Boards

**Operation ID:** `organizations-id-members-idmember-all`

**Endpoint:** `DELETE /organizations/{id}/members/{idMember}/all`

**Description:** Remove a member from a Workspace and from all Workspace boards

**Functions:**
- **Bash:** `trello_remove_member_from_organization_and_all_organization_boards`
- **PowerShell:** `Invoke-TrelloRemoveMemberFromOrganizationAndAllOrganizationBoards`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |

---

### Remove the associated Google Apps domain from a Workspace

**Operation ID:** `delete-organizations-id-prefs-associateddomain`

**Endpoint:** `DELETE /organizations/{id}/prefs/associatedDomain`

**Functions:**
- **Bash:** `trello_remove_associated_google_apps_domain_from_workspace`
- **PowerShell:** `Invoke-TrelloRemoveAssociatedGoogleAppsDomainFromWorkspace`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Delete the email domain restriction on who can be invited to the Workspace

**Operation ID:** `delete-organizations-id-prefs-orginviterestrict`

**Endpoint:** `DELETE /organizations/{id}/prefs/orgInviteRestrict`

**Description:** Remove the email domain restriction on who can be invited to the Workspace

**Functions:**
- **Bash:** `trello_delete_email_domain_restriction_on_who_can_be_invited_to_workspace`
- **PowerShell:** `Invoke-TrelloDeleteEmailDomainRestrictionOnWhoCanBeInvitedToWorkspace`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Delete an Organization's Tag

**Operation ID:** `delete-organizations-id-tags-idtag`

**Endpoint:** `DELETE /organizations/{id}/tags/{idTag}`

**Description:** Delete an organization's tag

**Functions:**
- **Bash:** `trello_delete_organizations_tag`
- **PowerShell:** `Invoke-TrelloDeleteOrganizationsTag`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idTag | string | path | Yes |

---
