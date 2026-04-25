# Plugins Endpoints

Total: 5 endpoints

## GET Requests

### Get a Plugin

**Operation ID:** `get-plugins-id`

**Endpoint:** `GET /plugins/{id}/`

**Description:** Get plugins

**Functions:**
- **Bash:** `get_plugin`
- **PowerShell:** `Invoke-GetPlugin`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

### Get Plugin's Member privacy compliance

**Operation ID:** `get-plugins-id-compliance-memberprivacy`

**Endpoint:** `GET /plugins/{id}/compliance/memberPrivacy`

**Functions:**
- **Bash:** `get_plugins_member_privacy_compliance`
- **PowerShell:** `Invoke-GetPluginsMemberPrivacyCompliance`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---

## POST Requests

### Create a Listing for Plugin

**Operation ID:** `post-plugins-idplugin-listing`

**Endpoint:** `POST /plugins/{idPlugin}/listing`

**Description:** Create a new listing for a given locale for your Power-Up

**Functions:**
- **Bash:** `create_listing_for_plugin`
- **PowerShell:** `Invoke-CreateListingForPlugin`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idPlugin | string | path | Yes |

---

## PUT Requests

### Updating Plugin's Listing

**Operation ID:** `put-plugins-idplugin-listings-idlisting`

**Endpoint:** `PUT /plugins/{idPlugin}/listings/{idListing}`

**Description:** Update an existing listing for your Power-Up

**Functions:**
- **Bash:** `updating_plugins_listing`
- **PowerShell:** `Invoke-UpdatingPluginsListing`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| idPlugin | string | path | Yes |
| idListing | string | path | Yes |

---

### Update a Plugin

**Operation ID:** `put-plugins-id`

**Endpoint:** `PUT /plugins/{id}/`

**Functions:**
- **Bash:** `update_plugin`
- **PowerShell:** `Invoke-UpdatePlugin`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |

---
