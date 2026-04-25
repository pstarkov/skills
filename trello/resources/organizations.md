# Organizations Endpoints

Total: 26 endpoints

## GET Requests

### Get an Organization

**Operation ID:** `get-organizations-id`

**Endpoint:** `GET /organizations/{id}`

**Functions:**
- **Bash:** `get_organization`
- **PowerShell:** `Invoke-GetOrganization`

---

### Get Actions for Organization

**Operation ID:** `get-organizations-id-actions`

**Endpoint:** `GET /organizations/{id}/actions`

**Description:** List the actions on a Workspace

**Functions:**
- **Bash:** `get_actions_for_organization`
- **PowerShell:** `Invoke-GetActionsForOrganization`

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
- **Bash:** `get_boards_in_organization`
- **PowerShell:** `Invoke-GetBoardsInOrganization`

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
- **Bash:** `retrieve_organizations_exports`
- **PowerShell:** `Invoke-RetrieveOrganizationsExports`

---

### Get the Members of an Organization

**Operation ID:** `get-organizations-id-members`

**Endpoint:** `GET /organizations/{id}/members`

**Description:** List the members in a Workspace

**Functions:**
- **Bash:** `get_members_organization`
- **PowerShell:** `Invoke-GetMembersOrganization`

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
- **Bash:** `get_memberships_organization`
- **PowerShell:** `Invoke-GetMembershipsOrganization`

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
- **Bash:** `get_membership_organization`
- **PowerShell:** `Invoke-GetMembershipOrganization`

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
- **Bash:** `get_organizations_new_billable_guests`
- **PowerShell:** `Invoke-GetOrganizationsNewBillableGuests`

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
- **Bash:** `get_plugindata_scoped_to_organization`
- **PowerShell:** `Invoke-GetPlugindataScopedToOrganization`

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
- **Bash:** `get_tags_organization`
- **PowerShell:** `Invoke-GetTagsOrganization`

---

### Get field on Organization

**Operation ID:** `get-organizations-id-field`

**Endpoint:** `GET /organizations/{id}/{field}`

**Functions:**
- **Bash:** `get_field_on_organization`
- **PowerShell:** `Invoke-GetFieldOnOrganization`

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
- **Bash:** `create_new_organization`
- **PowerShell:** `Invoke-CreateNewOrganization`

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
- **Bash:** `create_export_for_organizations`
- **PowerShell:** `Invoke-CreateExportForOrganizations`

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
- **Bash:** `update_logo_for_organization`
- **PowerShell:** `Invoke-UpdateLogoForOrganization`

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
- **Bash:** `create_tag_in_organization`
- **PowerShell:** `Invoke-CreateTagInOrganization`

---

## PUT Requests

### Update an Organization

**Operation ID:** `put-organizations-id`

**Endpoint:** `PUT /organizations/{id}`

**Description:** Update an organization

**Functions:**
- **Bash:** `update_organization`
- **PowerShell:** `Invoke-UpdateOrganization`

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
- **Bash:** `update_organizations_members`
- **PowerShell:** `Invoke-UpdateOrganizationsMembers`

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
- **Bash:** `update_member_organization`
- **PowerShell:** `Invoke-UpdateMemberOrganization`

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
- **Bash:** `deactivate_or_reactivate_member_organization`
- **PowerShell:** `Invoke-DeactivateOrReactivateMemberOrganization`

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
- **Bash:** `delete_organization`
- **PowerShell:** `Invoke-DeleteOrganization`

---

### Delete Logo for Organization

**Operation ID:** `delete-organizations-id-logo`

**Endpoint:** `DELETE /organizations/{id}/logo`

**Description:** Delete a the logo from a Workspace

**Functions:**
- **Bash:** `delete_logo_for_organization`
- **PowerShell:** `Invoke-DeleteLogoForOrganization`

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
- **Bash:** `remove_member_from_organization`
- **PowerShell:** `Invoke-RemoveMemberFromOrganization`

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
- **Bash:** `remove_member_from_organization_and_all_organization_boards`
- **PowerShell:** `Invoke-RemoveMemberFromOrganizationAndAllOrganizationBoards`

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
- **Bash:** `remove_associated_google_apps_domain_from_workspace`
- **PowerShell:** `Invoke-RemoveAssociatedGoogleAppsDomainFromWorkspace`

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
- **Bash:** `delete_email_domain_restriction_on_who_can_be_invited_to_workspace`
- **PowerShell:** `Invoke-DeleteEmailDomainRestrictionOnWhoCanBeInvitedToWorkspace`

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
- **Bash:** `delete_organizations_tag`
- **PowerShell:** `Invoke-DeleteOrganizationsTag`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idTag | string | path | Yes |

---
