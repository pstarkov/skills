# Notifications Endpoints

Total: 11 endpoints

## GET Requests

### Get a Notification

**Operation ID:** `get-notifications-id`

**Endpoint:** `GET /notifications/{id}`

**Functions:**
- **Bash:** `get_notification`
- **PowerShell:** `Invoke-GetNotification`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| board | boolean | query | No |
| board_fields | string | query | No |
| card | boolean | query | No |
| card_fields | string | query | No |
| display | boolean | query | No |
| entities | boolean | query | No |
| fields | string | query | No |
| list | boolean | query | No |
| member | boolean | query | No |
| member_fields | string | query | No |
| memberCreator | boolean | query | No |
| memberCreator_fields | string | query | No |
| organization | boolean | query | No |
| organization_fields | string | query | No |

---

### Get the Board a Notification is on

**Operation ID:** `get-notifications-id-board`

**Endpoint:** `GET /notifications/{id}/board`

**Description:** Get the board a notification is associated with

**Functions:**
- **Bash:** `get_board_notification_is_on`
- **PowerShell:** `Invoke-GetBoardNotificationIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Card a Notification is on

**Operation ID:** `get-notifications-id-card`

**Endpoint:** `GET /notifications/{id}/card`

**Description:** Get the card a notification is associated with

**Functions:**
- **Bash:** `get_card_notification_is_on`
- **PowerShell:** `Invoke-GetCardNotificationIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the List a Notification is on

**Operation ID:** `get-notifications-id-list`

**Endpoint:** `GET /notifications/{id}/list`

**Description:** Get the list a notification is associated with

**Functions:**
- **Bash:** `get_list_notification_is_on`
- **PowerShell:** `Invoke-GetListNotificationIsOn`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Member a Notification is about (not the creator)

**Operation ID:** `notificationsidmember`

**Endpoint:** `GET /notifications/{id}/member`

**Description:** Get the member (not the creator) a notification is about

**Functions:**
- **Bash:** `get_member_notification_is_about_not_creator`
- **PowerShell:** `Invoke-GetMemberNotificationIsAboutNotCreator`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get the Member who created the Notification

**Operation ID:** `get-notifications-id-membercreator`

**Endpoint:** `GET /notifications/{id}/memberCreator`

**Description:** Get the member who created the notification

**Functions:**
- **Bash:** `get_member_who_created_notification`
- **PowerShell:** `Invoke-GetMemberWhoCreatedNotification`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get a Notification's associated Organization

**Operation ID:** `get-notifications-id-organization`

**Endpoint:** `GET /notifications/{id}/organization`

**Description:** Get the organization a notification is associated with

**Functions:**
- **Bash:** `get_notifications_associated_organization`
- **PowerShell:** `Invoke-GetNotificationsAssociatedOrganization`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| fields | string | query | No |

---

### Get a field of a Notification

**Operation ID:** `get-notifications-id-field`

**Endpoint:** `GET /notifications/{id}/{field}`

**Description:** Get a specific property of a notification

**Functions:**
- **Bash:** `get_field_notification`
- **PowerShell:** `Invoke-GetFieldNotification`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| field | string | path | Yes |

---

## POST Requests

### Mark all Notifications as read

**Operation ID:** `post-notifications-all-read`

**Endpoint:** `POST /notifications/all/read`

**Description:** Mark all notifications as read

**Functions:**
- **Bash:** `mark_all_notifications_as_read`
- **PowerShell:** `Invoke-MarkAllNotificationsAsRead`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| read | boolean | query | No |
| ids | array | query | No |

---

## PUT Requests

### Update a Notification's read status

**Operation ID:** `put-notifications-id`

**Endpoint:** `PUT /notifications/{id}`

**Description:** Update the read status of a notification

**Functions:**
- **Bash:** `update_notification`
- **PowerShell:** `Invoke-UpdateNotification`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| unread | boolean | query | No |

---

### Update Notification's read status

**Operation ID:** `put-notifications-id-unread`

**Endpoint:** `PUT /notifications/{id}/unread`

**Functions:**
- **Bash:** `mark_notification_unread`
- **PowerShell:** `Invoke-MarkNotificationUnread`

**Parameters:**

| Name | Type | Location | Required |
|------|------|----------|----------|
| id | string | path | Yes |
| value | string | query | No |

---
