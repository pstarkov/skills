# Enterprises Endpoints

Total: 21 endpoints

## GET Requests

### Get an Enterprise

**Operation ID:** `get-enterprises-id`

**Endpoint:** `GET /enterprises/{id}`

**Description:** Get an enterprise by its ID.

**Functions:**
- **Bash:** `trello_get_enterprise`
- **PowerShell:** `Invoke-TrelloGetEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |
| members | string | query | No |
| member_fields | string | query | No |
| member_filter | string | query | No |
| member_sort | string | query | No |
| member_sortBy | string | query | No |
| member_sortOrder | string | query | No |
| member_startIndex | integer | query | No |
| member_count | integer | query | No |
| organizations | string | query | No |
| organization_fields | string | query | No |
| organization_paid_accounts | boolean | query | No |
| organization_memberships | string | query | No |

---

### Get Enterprise admin Members

**Operation ID:** `get-enterprises-id-admins`

**Endpoint:** `GET /enterprises/{id}/admins`

**Description:** Get an enterprise's admin members.

**Functions:**
- **Bash:** `trello_get_enterprise_admin_members`
- **PowerShell:** `Invoke-TrelloGetEnterpriseAdminMembers`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get auditlog data for an Enterprise

**Operation ID:** `get-enterprises-id-auditlog`

**Endpoint:** `GET /enterprises/{id}/auditlog`

**Description:** Returns an array of Actions related to the Enterprise object. Used for populating data sent to Google Sheets from an Enterprise's audit log page: https://trello.com/e/{enterprise_name}/admin/auditlog....

**Functions:**
- **Bash:** `trello_get_auditlog_data_for_enterprise`
- **PowerShell:** `Invoke-TrelloGetAuditlogDataForEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get ClaimableOrganizations of an Enterprise

**Operation ID:** `get-enterprises-id-claimableOrganizations`

**Endpoint:** `GET /enterprises/{id}/claimableOrganizations`

**Description:** Get the Workspaces that are claimable by the enterprise by ID. Can optionally query for workspaces based on activeness/ inactiveness.

**Functions:**
- **Bash:** `trello_get_claimableorganizations_enterprise`
- **PowerShell:** `Invoke-TrelloGetClaimableorganizationsEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| limit | integer | query | No |
| cursor | string | query | No |
| name | string | query | No |
| activeSince | string | query | No |
| inactiveSince | string | query | No |

---

### Get Members of Enterprise

**Operation ID:** `get-enterprises-id-members`

**Endpoint:** `GET /enterprises/{id}/members`

**Description:** Get the members of an enterprise.

**Functions:**
- **Bash:** `trello_get_members_enterprise`
- **PowerShell:** `Invoke-TrelloGetMembersEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |
| filter | string | query | No |
| sort | string | query | No |
| sortBy | string | query | No |
| sortOrder | string | query | No |
| startIndex | integer | query | No |
| count | string | query | No |
| organization_fields | string | query | No |
| board_fields | string | query | No |

---

### Get Users of an Enterprise

**Operation ID:** `get-users-id`

**Endpoint:** `GET /enterprises/{id}/members/query`

**Description:** Get an enterprise's users. You can choose to retrieve licensed members, board guests, etc. The response is paginated and will return 100 users at a time.

**Functions:**
- **Bash:** `trello_get_users_enterprise`
- **PowerShell:** `Invoke-TrelloGetUsersEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| licensed | boolean | query | No |
| deactivated | boolean | query | No |
| collaborator | boolean | query | No |
| managed | boolean | query | No |
| admin | boolean | query | No |
| activeSince | string | query | No |
| inactiveSince | string | query | No |
| search | string | query | No |
| cursor | string | query | No |

---

### Get a Member of Enterprise

**Operation ID:** `get-enterprises-id-members-idmember`

**Endpoint:** `GET /enterprises/{id}/members/{idMember}`

**Description:** Get a specific member of an enterprise by ID.

**Functions:**
- **Bash:** `trello_get_member_enterprise`
- **PowerShell:** `Invoke-TrelloGetMemberEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |
| fields | string | query | No |
| organization_fields | string | query | No |
| board_fields | string | query | No |

---

### Get Organizations of an Enterprise

**Operation ID:** `get-enterprises-id-organizations`

**Endpoint:** `GET /enterprises/{id}/organizations`

**Description:** Get the organizations of an enterprise.

**Functions:**
- **Bash:** `trello_get_organizations_enterprise`
- **PowerShell:** `Invoke-TrelloGetOrganizationsEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |
| filter | string | query | No |
| startIndex | integer | query | No |
| count | integer | query | No |

---

### Bulk accept a set of organizations to an Enterprise.

**Operation ID:** `get-enterprises-id-organizations-bulk-idOrganizations`

**Endpoint:** `GET /enterprises/{id}/organizations/bulk/{idOrganizations}`

**Description:** Accept an array of organizations to an enterprise.

 NOTE: For enterprises that have opted in to user management via AdminHub, this endpoint will result in organizations being added to the enterprise ...

**Functions:**
- **Bash:** `trello_bulk_accept_set_organizations_to_enterprise`
- **PowerShell:** `Invoke-TrelloBulkAcceptSetOrganizationsToEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idOrganizations | array | path | Yes |

---

### Get PendingOrganizations of an Enterprise

**Operation ID:** `get-enterprises-id-pendingOrganizations`

**Endpoint:** `GET /enterprises/{id}/pendingOrganizations`

**Description:** Get the Workspaces that are pending for the enterprise by ID.

**Functions:**
- **Bash:** `trello_get_pendingorganizations_enterprise`
- **PowerShell:** `Invoke-TrelloGetPendingorganizationsEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| activeSince | string | query | No |
| inactiveSince | string | query | No |

---

### Get signupUrl for Enterprise

**Operation ID:** `get-enterprises-id-signupurl`

**Endpoint:** `GET /enterprises/{id}/signupUrl`

**Description:** Get the signup URL for an enterprise.

**Functions:**
- **Bash:** `trello_get_signupurl_for_enterprise`
- **PowerShell:** `Invoke-TrelloGetSignupurlForEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| authenticate | boolean | query | No |
| confirmationAccepted | boolean | query | No |
| returnUrl | string | query | No |
| tosAccepted | boolean | query | No |

---

### Get a bulk list of organizations that can be transferred to an enterprise.

**Operation ID:** `get-enterprises-id-transferrable-bulk-idOrganizations`

**Endpoint:** `GET /enterprises/{id}/transferrable/bulk/{idOrganizations}`

**Description:** Get a list of organizations that can be transferred to an enterprise when given a bulk list of organizations.

**Functions:**
- **Bash:** `trello_get_bulk_list_organizations_that_can_be_transferred_to_enterprise`
- **PowerShell:** `Invoke-TrelloGetBulkListOrganizationsThatCanBeTransferredToEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idOrganizations | array | path | Yes |

---

### Get whether an organization can be transferred to an enterprise.

**Operation ID:** `get-enterprises-id-transferrable-organization-idOrganization`

**Endpoint:** `GET /enterprises/{id}/transferrable/organization/{idOrganization}`

**Functions:**
- **Bash:** `trello_get_whether_organization_can_be_transferred_to_enterprise`
- **PowerShell:** `Invoke-TrelloGetWhetherOrganizationCanBeTransferredToEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idOrganization | string | path | Yes |

---

## POST Requests

### Create an auth Token for an Enterprise.

**Operation ID:** `post-enterprises-id-tokens`

**Endpoint:** `POST /enterprises/{id}/tokens`

**Functions:**
- **Bash:** `trello_create_auth_token_for_enterprise`
- **PowerShell:** `Invoke-TrelloCreateAuthTokenForEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| expiration | string | query | No |

---

## PUT Requests

### Decline enterpriseJoinRequests from one organization or a bulk list of organizations.

**Operation ID:** `put-enterprises-id-enterpriseJoinRequest-bulk`

**Endpoint:** `PUT /enterprises/${id}/enterpriseJoinRequest/bulk`

**Description:** Decline enterpriseJoinRequests from one organization or bulk amount of organizations

**Functions:**
- **Bash:** `trello_decline_enterprisejoinrequests_from_one_organization_or_bulk_list_organizations`
- **PowerShell:** `Invoke-TrelloDeclineEnterprisejoinrequestsFromOneOrganizationOrBulkListOrganizations`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idOrganizations | array | query | Yes |

---

### Update Member to be admin of Enterprise

**Operation ID:** `put-enterprises-id-admins-idmember`

**Endpoint:** `PUT /enterprises/{id}/admins/{idMember}`

**Description:** Make Member an admin of Enterprise.

 NOTE: This endpoint is not available to enterprises that have opted in to user management via AdminHub.

**Functions:**
- **Bash:** `trello_update_member_to_be_admin_enterprise`
- **PowerShell:** `Invoke-TrelloUpdateMemberToBeAdminEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |

---

### Deactivate a Member of an Enterprise.

**Operation ID:** `enterprises-id-members-idMember-deactivated`

**Endpoint:** `PUT /enterprises/{id}/members/{idMember}/deactivated`

**Description:** Deactivate a Member of an Enterprise.

 NOTE: Deactivation is not possible for enterprises that have opted in to user management via AdminHub.

**Functions:**
- **Bash:** `trello_deactivate_member_enterprise`
- **PowerShell:** `Invoke-TrelloDeactivateMemberEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |
| value | boolean | query | Yes |
| fields | string | query | No |
| organization_fields | string | query | No |
| board_fields | string | query | No |

---

### Update a Member's licensed status

**Operation ID:** `put-enterprises-id-members-idmember-licensed`

**Endpoint:** `PUT /enterprises/{id}/members/{idMember}/licensed`

**Description:** This endpoint is used to update whether the provided Member should use one of the Enterprise's available licenses or not. Revoking a license will deactivate a Member of an Enterprise. 

 NOTE: Revokin...

**Functions:**
- **Bash:** `trello_update_members_licensed_status`
- **PowerShell:** `Invoke-TrelloUpdateMembersLicensedStatus`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |
| value | boolean | query | Yes |

---

### Transfer an Organization to an Enterprise.

**Operation ID:** `put-enterprises-id-organizations`

**Endpoint:** `PUT /enterprises/{id}/organizations`

**Description:** Transfer an organization to an enterprise.

 NOTE: For enterprises that have opted in to user management via AdminHub, this endpoint will result in the organization being added to the enterprise async...

**Functions:**
- **Bash:** `trello_transfer_organization_to_enterprise`
- **PowerShell:** `Invoke-TrelloTransferOrganizationToEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idOrganization | string | query | Yes |

---

## DELETE Requests

### Remove a Member as admin from Enterprise.

**Operation ID:** `enterprises-id-organizations-idmember`

**Endpoint:** `DELETE /enterprises/{id}/admins/{idMember}`

**Description:** Remove a member as admin from an enterprise.

 NOTE: This endpoint is not available to enterprises that have opted in to user management via AdminHub.

**Functions:**
- **Bash:** `trello_remove_member_as_admin_from_enterprise`
- **PowerShell:** `Invoke-TrelloRemoveMemberAsAdminFromEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idMember | string | path | Yes |

---

### Delete an Organization from an Enterprise.

**Operation ID:** `delete-enterprises-id-organizations-idorg`

**Endpoint:** `DELETE /enterprises/{id}/organizations/{idOrg}`

**Description:** Remove an organization from an enterprise.

**Functions:**
- **Bash:** `trello_delete_organization_from_enterprise`
- **PowerShell:** `Invoke-TrelloDeleteOrganizationFromEnterprise`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| idOrg | string | path | Yes |

---
