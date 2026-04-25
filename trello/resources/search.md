# Search Endpoints

Total: 2 endpoints

## GET Requests

### Search Trello

**Operation ID:** `get-search`

**Endpoint:** `GET /search`

**Description:** Find what you're looking for in Trello

**Functions:**
- **Bash:** `search_trello`
- **PowerShell:** `Invoke-SearchTrello`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| query | string | query | Yes |
| idBoards | string | query | No |
| idOrganizations | string | query | No |
| idCards | string | query | No |
| modelTypes | string | query | No |
| board_fields | string | query | No |
| boards_limit | integer | query | No |
| board_organization | boolean | query | No |
| card_fields | string | query | No |
| cards_limit | integer | query | No |
| cards_page | number | query | No |
| card_board | boolean | query | No |
| card_list | boolean | query | No |
| card_members | boolean | query | No |
| card_stickers | boolean | query | No |
| card_attachments | string | query | No |
| organization_fields | string | query | No |
| organizations_limit | integer | query | No |
| member_fields | string | query | No |
| members_limit | integer | query | No |
| partial | boolean | query | No |

---

### Search for Members

**Operation ID:** `get-search-members`

**Endpoint:** `GET /search/members/`

**Description:** Search for Trello members.

**Functions:**
- **Bash:** `search_for_members`
- **PowerShell:** `Invoke-SearchForMembers`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| query | string | query | Yes |
| limit | integer | query | No |
| idBoard | string | query | No |
| idOrganization | string | query | No |
| onlyOrgMembers | boolean | query | No |

---
