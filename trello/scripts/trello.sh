#!/usr/bin/env bash
# Trello REST API - Consolidated Bash Functions
# This script contains all endpoint functions for the Trello REST API
# Source this file: source trello.sh
#
# Environment variables required:
#   TRELLO_API_KEY - Your Trello API key
#   TRELLO_TOKEN   - Your Trello API token
#
# Examples:
#   export TRELLO_API_KEY="your_key"
#   export TRELLO_TOKEN="your_token"
#   trello_get_action id=abc123
#   trello_create_card idList=xyz name="My Card"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Validate that Trello API credentials are configured in environment
# Returns 0 if valid, 1 if missing
trello_require_authentication() {
    if [ -z "${TRELLO_API_KEY:-}" ]; then
        echo "Error: TRELLO_API_KEY environment variable not set" >&2
        return 1
    fi
    if [ -z "${TRELLO_TOKEN:-}" ]; then
        echo "Error: TRELLO_TOKEN environment variable not set" >&2
        return 1
    fi
    return 0
}

# URL-encode a value for use in path segments and query strings.
trello_urlencode() {
    local value="${1}"
    local encoded=""
    local char
    local i

    local LC_ALL=C
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "${char}" in
            [a-zA-Z0-9.~_-]) encoded+="${char}" ;;
            *) printf -v char '%%%02X' "'${char}"; encoded+="${char}" ;;
        esac
    done
    printf '%s' "${encoded}"
}

# Return 0 if PATH contains a {name} or ${name} placeholder.
trello_path_has_placeholder() {
    local path="${1}"
    local name="${2}"

    [[ "${path}" == *"{$name}"* || "${path}" == *"\${$name}"* ]]
}

# Replace {name} and ${name} placeholders in PATH with VALUE.
trello_replace_path_placeholder() {
    local path="${1}"
    local name="${2}"
    local value="${3}"

    value="$(trello_urlencode "${value}")"
    path="${path//\{$name\}/${value}}"
    path="${path//\$\{$name\}/${value}}"
    printf '%s' "${path}"
}

# Make an authenticated request to the Trello API
# Usage: trello_request METHOD PATH [key=value ...] [JSON_BODY]
# Examples:
#   trello_request GET /cards/abc123
#   trello_request GET /boards/{id} id=xyz fields=name,desc
#   trello_request POST /cards idList=abc123 '{"name":"Card","desc":"Description"}'
#
# Returns:
#   - stdout: API response (JSON)
#   - exit code: curl exit code (0 = success)
trello_request() {
    local method="${1}"
    local path="${2}"
    shift 2

    local arg
    local key
    local value
    local body=""
    local query=""
    local encoded_key
    local encoded_value
    local placeholder
    
    trello_require_authentication || return 1

    for arg in "$@"; do
        if [[ -z "${body}" && ( "${arg}" == \{* || "${arg}" == \[* ) ]]; then
            body="${arg}"
        elif [[ "${arg}" == *=* ]]; then
            key="${arg%%=*}"
            value="${arg#*=}"

            if trello_path_has_placeholder "${path}" "${key}"; then
                path="$(trello_replace_path_placeholder "${path}" "${key}" "${value}")"
            else
                encoded_key="$(trello_urlencode "${key}")"
                encoded_value="$(trello_urlencode "${value}")"
                if [ -z "${query}" ]; then
                    query="${encoded_key}=${encoded_value}"
                else
                    query="${query}&${encoded_key}=${encoded_value}"
                fi
            fi
        elif [ -z "${body}" ]; then
            body="${arg}"
        else
            echo "Error: unexpected extra argument: ${arg}" >&2
            return 1
        fi
    done

    while [[ "${path}" =~ (\$\{?[A-Za-z_][A-Za-z0-9_]*\}?|\{[A-Za-z_][A-Za-z0-9_]*\}) ]]; do
        placeholder="${BASH_REMATCH[1]}"
        placeholder="${placeholder#\{}"
        placeholder="${placeholder%\}}"
        placeholder="${placeholder#\$\{}"
        placeholder="${placeholder%\}}"
        echo "Error: missing required path parameter: ${placeholder}" >&2
        return 1
    done
    
    local url="https://api.trello.com/1${path}"
    local auth_query="key=$(trello_urlencode "${TRELLO_API_KEY}")&token=$(trello_urlencode "${TRELLO_TOKEN}")"
    
    # Add API credentials to query string
    if [ -z "${query}" ]; then
        url="${url}?${auth_query}"
    else
        url="${url}?${auth_query}&${query}"
    fi
    
    # Make request
    if [ -n "${body}" ]; then
        # POST/PUT with JSON body
        curl -s -X "${method}" \
            -H "Content-Type: application/json" \
            -d "${body}" \
            "${url}"
    else
        # GET/DELETE or other methods
        curl -s -X "${method}" "${url}"
    fi
}

# ============================================================================
# ENDPOINT FUNCTIONS
# ============================================================================

# GET /applications/{key}/compliance
# Get Application's compliance data
trello_get_applications_compliance_data() {
    trello_request GET /applications/{key}/compliance "$@"
}

# GET /boards/{id}/checklists
# Get Checklists on a Board
# Get all of the checklists on a Board.
trello_get_checklists_on_board() {
    trello_request GET /boards/{id}/checklists "$@"
}

# DELETE /boards/{id}/members/{idMember}
# Remove Member from Board
trello_remove_member_from_board() {
    trello_request DELETE /boards/{id}/members/{idMember} "$@"
}

# POST /cards/{id}/membersVoted
# Add Member vote to Card
# Vote on the card for a given member.
trello_add_member_vote_to_card() {
    trello_request POST /cards/{id}/membersVoted "$@"
}

# DELETE /actions/{id}
# Delete an Action
# Delete a specific action. Only comment actions can be deleted.
trello_delete_action() {
    trello_request DELETE /actions/{id} "$@"
}

# DELETE /actions/{idAction}/reactions/{id}
# Delete Action's Reaction
# Deletes a reaction
trello_delete_actions_reaction() {
    trello_request DELETE /actions/{idAction}/reactions/{id} "$@"
}

# DELETE /boards/{id}
# Delete a Board
# Delete a board.
trello_delete_board() {
    trello_request DELETE /boards/{id} "$@"
}

# DELETE /boards/{id}/boardPlugins/{idPlugin}
# Disable a Power-Up on a Board
# Disable a Power-Up on a board
trello_disable_powerup_on_board() {
    trello_request DELETE /boards/{id}/boardPlugins/{idPlugin} "$@"
}

# DELETE /cards/{id}
# Delete a Card
trello_delete_card() {
    trello_request DELETE /cards/{id} "$@"
}

# DELETE /cards/{id}/actions/{idAction}/comments
# Delete a comment on a Card
# Delete a comment
trello_delete_comment_on_card() {
    trello_request DELETE /cards/{id}/actions/{idAction}/comments "$@"
}

# DELETE /cards/{id}/checkItem/{idCheckItem}
# Delete checkItem on a Card
# Delete a checklist item
trello_delete_checkitem_on_card() {
    trello_request DELETE /cards/{id}/checkItem/{idCheckItem} "$@"
}

# DELETE /cards/{id}/checklists/{idChecklist}
# Delete a Checklist on a Card
# Delete a checklist from a card
trello_delete_checklist_on_card() {
    trello_request DELETE /cards/{id}/checklists/{idChecklist} "$@"
}

# DELETE /cards/{id}/idLabels/{idLabel}
# Remove a Label from a Card
# Remove a label from a card
trello_remove_label_from_card() {
    trello_request DELETE /cards/{id}/idLabels/{idLabel} "$@"
}

# DELETE /cards/{id}/membersVoted/{idMember}
# Remove a Member's Vote on a Card
# Remove a member's vote from a card
trello_remove_members_vote_on_card() {
    trello_request DELETE /cards/{id}/membersVoted/{idMember} "$@"
}

# DELETE /cards/{id}/stickers/{idSticker}
# Delete a Sticker on a Card
# Remove a sticker from the card
trello_delete_sticker_on_card() {
    trello_request DELETE /cards/{id}/stickers/{idSticker} "$@"
}

# DELETE /checklists/{id}
# Delete a Checklist
# Delete a checklist
trello_delete_checklist() {
    trello_request DELETE /checklists/{id} "$@"
}

# DELETE /checklists/{id}/checkItems/{idCheckItem}
# Delete Checkitem from Checklist
# Remove an item from a checklist
trello_delete_checkitem_from_checklist() {
    trello_request DELETE /checklists/{id}/checkItems/{idCheckItem} "$@"
}

# DELETE /customFields/{id}
# Delete a Custom Field definition
# Delete a Custom Field from a board.
trello_delete_custom_field_definition() {
    trello_request DELETE /customFields/{id} "$@"
}

# DELETE /customFields/{id}/options/{idCustomFieldOption}
# Delete Option of Custom Field dropdown
# Delete an option from a Custom Field dropdown.
trello_delete_option_custom_field_dropdown() {
    trello_request DELETE /customFields/{id}/options/{idCustomFieldOption} "$@"
}

# DELETE /enterprises/{id}/organizations/{idOrg}
# Delete an Organization from an Enterprise.
# Remove an organization from an enterprise.
trello_delete_organization_from_enterprise() {
    trello_request DELETE /enterprises/{id}/organizations/{idOrg} "$@"
}

# DELETE /cards/{id}/idMembers/{idMember}
# Remove a Member from a Card
# Remove a member from a card
trello_remove_member_from_card() {
    trello_request DELETE /cards/{id}/idMembers/{idMember} "$@"
}

# DELETE /labels/{id}
# Delete a Label
# Delete a label by ID.
trello_delete_label() {
    trello_request DELETE /labels/{id} "$@"
}

# DELETE /members/{id}/boardBackgrounds/{idBackground}
# Delete a Member's custom Board background
# Delete a board background
trello_delete_members_custom_board_background() {
    trello_request DELETE /members/{id}/boardBackgrounds/{idBackground} "$@"
}

# DELETE /members/{id}/boardStars/{idStar}
# Delete Star for Board
# Unstar a board
trello_delete_star_for_board() {
    trello_request DELETE /members/{id}/boardStars/{idStar} "$@"
}

# DELETE /members/{id}/customBoardBackgrounds/{idBackground}
# Delete custom Board Background of Member
# Delete a specific custom board background
trello_delete_custom_board_background_member() {
    trello_request DELETE /members/{id}/customBoardBackgrounds/{idBackground} "$@"
}

# DELETE /members/{id}/customStickers/{idSticker}
# Delete a Member's custom Sticker
trello_delete_members_custom_sticker() {
    trello_request DELETE /members/{id}/customStickers/{idSticker} "$@"
}

# DELETE /members/{id}/savedSearches/{idSearch}
# Delete a saved search
trello_delete_saved_search() {
    trello_request DELETE /members/{id}/savedSearches/{idSearch} "$@"
}

# DELETE /organizations/{id}
# Delete an Organization
trello_delete_organization() {
    trello_request DELETE /organizations/{id} "$@"
}

# DELETE /organizations/{id}/logo
# Delete Logo for Organization
# Delete a the logo from a Workspace
trello_delete_logo_for_organization() {
    trello_request DELETE /organizations/{id}/logo "$@"
}

# DELETE /organizations/{id}/members/{idMember}
# Remove a Member from an Organization
# Remove a member from a Workspace
trello_remove_member_from_organization() {
    trello_request DELETE /organizations/{id}/members/{idMember} "$@"
}

# DELETE /organizations/{id}/prefs/associatedDomain
# Remove the associated Google Apps domain from a Workspace
trello_remove_associated_google_apps_domain_from_workspace() {
    trello_request DELETE /organizations/{id}/prefs/associatedDomain "$@"
}

# DELETE /organizations/{id}/prefs/orgInviteRestrict
# Delete the email domain restriction on who can be invited to the Workspace
# Remove the email domain restriction on who can be invited to the Workspace
trello_delete_email_domain_restriction_on_who_can_be_invited_to_workspace() {
    trello_request DELETE /organizations/{id}/prefs/orgInviteRestrict "$@"
}

# DELETE /organizations/{id}/tags/{idTag}
# Delete an Organization's Tag
# Delete an organization's tag
trello_delete_organizations_tag() {
    trello_request DELETE /organizations/{id}/tags/{idTag} "$@"
}

# DELETE /tokens/{token}/
# Delete a Token
# Delete a token.
trello_delete_token() {
    trello_request DELETE /tokens/{token}/ "$@"
}

# DELETE /tokens/{token}/webhooks/{idWebhook}
# Delete a Webhook created by Token
# Delete a webhook created with given token.
trello_delete_webhook_created_by_token() {
    trello_request DELETE /tokens/{token}/webhooks/{idWebhook} "$@"
}

# DELETE /webhooks/{id}
# Delete a Webhook
# Delete a webhook by ID.
trello_delete_webhook() {
    trello_request DELETE /webhooks/{id} "$@"
}

# DELETE /cards/{id}/attachments/{idAttachment}
# Delete an Attachment on a Card
# Delete an Attachment
trello_delete_attachment_on_card() {
    trello_request DELETE /cards/{id}/attachments/{idAttachment} "$@"
}

# GET /emoji
# List available Emoji
trello_list_available_emoji() {
    trello_request GET /emoji "$@"
}

# PUT /enterprises/{id}/members/{idMember}/deactivated
# Deactivate a Member of an Enterprise.
# Deactivate a Member of an Enterprise.

# NOTE: Deactivation is not possible for enterprises that have
trello_deactivate_member_enterprise() {
    trello_request PUT /enterprises/{id}/members/{idMember}/deactivated "$@"
}

# DELETE /enterprises/{id}/admins/{idMember}
# Remove a Member as admin from Enterprise.
# Remove a member as admin from an enterprise.

# NOTE: This endpoint is not available to enterprises t
trello_remove_member_as_admin_from_enterprise() {
    trello_request DELETE /enterprises/{id}/admins/{idMember} "$@"
}

# GET /actions/{id}
# Get an Action
trello_get_action() {
    trello_request GET /actions/{id} "$@"
}

# GET /actions/{id}/board
# Get the Board for an Action
trello_get_board_for_action() {
    trello_request GET /actions/{id}/board "$@"
}

# GET /actions/{id}/card
# Get the Card for an Action
# Get the card for an action
trello_get_card_for_action() {
    trello_request GET /actions/{id}/card "$@"
}

# GET /actions/{id}/{field}
# Get a specific field on an Action
# Get a specific property of an action
trello_get_specific_field_on_action() {
    trello_request GET /actions/{id}/{field} "$@"
}

# GET /actions/{id}/list
# Get the List for an Action
trello_get_list_for_action() {
    trello_request GET /actions/{id}/list "$@"
}

# GET /actions/{id}/member
# Get the Member of an Action
# Gets the member of an action (not the creator)
trello_get_member_action() {
    trello_request GET /actions/{id}/member "$@"
}

# GET /actions/{id}/memberCreator
# Get the Member Creator of an Action
# Get the Member who created the Action
trello_get_member_creator_action() {
    trello_request GET /actions/{id}/memberCreator "$@"
}

# GET /actions/{id}/organization
# Get the Organization of an Action
trello_get_organization_action() {
    trello_request GET /actions/{id}/organization "$@"
}

# GET /actions/{idAction}/reactions
# Get Action's Reactions
# List reactions for an action
trello_get_actions_reactions() {
    trello_request GET /actions/{idAction}/reactions "$@"
}

# GET /actions/{idAction}/reactions/{id}
# Get Action's Reaction
# Get information for a reaction
trello_get_actions_reaction() {
    trello_request GET /actions/{idAction}/reactions/{id} "$@"
}

# GET /actions/{idAction}/reactionsSummary
# List Action's summary of Reactions
# List a summary of all reactions for an action
trello_list_actions_summary_reactions() {
    trello_request GET /actions/{idAction}/reactionsSummary "$@"
}

# GET /batch
# Batch Requests
# Make up to 10 GET requests in a single, batched API call.
trello_batch_requests() {
    trello_request GET /batch "$@"
}

# GET /boards/{id}/plugins
# Get Power-Ups on a Board
# List the Power-Ups on a board
trello_get_powerups_on_board() {
    trello_request GET /boards/{id}/plugins "$@"
}

# GET /boards/{id}
# Get a Board
# Request a single board.
trello_get_board() {
    trello_request GET /boards/{id} "$@"
}

# GET /boards/{boardId}/actions
# Get Actions of a Board
# Get all of the actions of a Board. See [Nested Resources](/cloud/trello/guides/rest-api/nested-resou
trello_get_actions_board() {
    trello_request GET /boards/{boardId}/actions "$@"
}

# GET /boards/{id}/boardPlugins
# Get Enabled Power-Ups on Board
# Get the enabled Power-Ups on a board
trello_get_enabled_powerups_on_board() {
    trello_request GET /boards/{id}/boardPlugins "$@"
}

# GET /boards/{boardId}/boardStars
# Get boardStars on a Board
trello_get_boardstars_on_board() {
    trello_request GET /boards/{boardId}/boardStars "$@"
}

# GET /boards/{id}/cards
# Get Cards on a Board
# Get all of the open Cards on a Board. See [Nested Resources](/cloud/trello/guides/rest-api/nested-re
trello_get_cards_on_board() {
    trello_request GET /boards/{id}/cards "$@"
}

# GET /boards/{id}/cards/{filter}
# Get filtered Cards on a Board
# Get the Cards on a Board that match a given filter. See [Nested Resources](/cloud/trello/guides/rest
trello_get_filtered_cards_on_board() {
    trello_request GET /boards/{id}/cards/{filter} "$@"
}

# GET /boards/{id}/customFields
# Get Custom Fields for Board
# Get the Custom Field Definitions that exist on a board.
trello_get_custom_fields_for_board() {
    trello_request GET /boards/{id}/customFields "$@"
}

# GET /boards/{id}/{field}
# Get a field on a Board
# Get a single, specific field on a board
trello_get_field_on_board() {
    trello_request GET /boards/{id}/{field} "$@"
}

# GET /boards/{id}/labels
# Get Labels on a Board
# Get all of the Labels on a Board.
trello_get_labels_on_board() {
    trello_request GET /boards/{id}/labels "$@"
}

# GET /boards/{id}/lists
# Get Lists on a Board
# Get the Lists on a Board
trello_get_lists_on_board() {
    trello_request GET /boards/{id}/lists "$@"
}

# GET /boards/{id}/lists/{filter}
# Get filtered Lists on a Board
trello_get_filtered_lists_on_board() {
    trello_request GET /boards/{id}/lists/{filter} "$@"
}

# GET /boards/{id}/members
# Get the Members of a Board
# Get the Members for a board
trello_get_members_board() {
    trello_request GET /boards/{id}/members "$@"
}

# GET /boards/{id}/memberships
# Get Memberships of a Board
# Get information about the memberships users have to the board.
trello_get_memberships_board() {
    trello_request GET /boards/{id}/memberships "$@"
}

# GET /cards/{id}
# Get a Card
# Get a card by its ID
trello_get_card() {
    trello_request GET /cards/{id} "$@"
}

# GET /cards/{id}/actions
# Get Actions on a Card
# List the Actions on a Card. See [Nested Resources](/cloud/trello/guides/rest-api/nested-resources/) 
trello_get_actions_on_card() {
    trello_request GET /cards/{id}/actions "$@"
}

# GET /cards/{id}/attachments
# Get Attachments on a Card
# List the attachments on a card
trello_get_attachments_on_card() {
    trello_request GET /cards/{id}/attachments "$@"
}

# GET /cards/{id}/attachments/{idAttachment}
# Get an Attachment on a Card
# Get a specific Attachment on a Card.
trello_get_attachment_on_card() {
    trello_request GET /cards/{id}/attachments/{idAttachment} "$@"
}

# GET /cards/{id}/board
# Get the Board the Card is on
# Get the board a card is on
trello_get_board_card_is_on() {
    trello_request GET /cards/{id}/board "$@"
}

# GET /cards/{id}/checkItem/{idCheckItem}
# Get checkItem on a Card
# Get a specific checkItem on a card
trello_get_checkitem_on_card() {
    trello_request GET /cards/{id}/checkItem/{idCheckItem} "$@"
}

# GET /cards/{id}/checkItemStates
# Get checkItems on a Card
# Get the completed checklist items on a card
trello_get_checkitems_on_card() {
    trello_request GET /cards/{id}/checkItemStates "$@"
}

# GET /cards/{id}/checklists
# Get Checklists on a Card
# Get the checklists on a card
trello_get_checklists_on_card() {
    trello_request GET /cards/{id}/checklists "$@"
}

# GET /cards/{id}/customFieldItems
# Get Custom Field Items for a Card
# Get the custom field items for a card.
trello_get_custom_field_items_for_card() {
    trello_request GET /cards/{id}/customFieldItems "$@"
}

# GET /cards/{id}/{field}
# Get a field on a Card
# Get a specific property of a card
trello_get_field_on_card() {
    trello_request GET /cards/{id}/{field} "$@"
}

# GET /cards/{id}/list
# Get the List of a Card
# Get the list a card is in
trello_get_list_card() {
    trello_request GET /cards/{id}/list "$@"
}

# GET /cards/{id}/members
# Get the Members of a Card
# Get the members on a card
trello_get_members_card() {
    trello_request GET /cards/{id}/members "$@"
}

# GET /cards/{id}/membersVoted
# Get Members who have voted on a Card
# Get the members who have voted on a card
trello_get_members_who_have_voted_on_card() {
    trello_request GET /cards/{id}/membersVoted "$@"
}

# GET /cards/{id}/pluginData
# Get pluginData on a Card
# Get any shared pluginData on a card.
trello_get_plugindata_on_card() {
    trello_request GET /cards/{id}/pluginData "$@"
}

# GET /cards/{id}/stickers
# Get Stickers on a Card
# Get the stickers on a card
trello_get_stickers_on_card() {
    trello_request GET /cards/{id}/stickers "$@"
}

# GET /cards/{id}/stickers/{idSticker}
# Get a Sticker on a Card
# Get a specific sticker on a card
trello_get_sticker_on_card() {
    trello_request GET /cards/{id}/stickers/{idSticker} "$@"
}

# GET /checklists/{id}
# Get a Checklist
trello_get_checklist() {
    trello_request GET /checklists/{id} "$@"
}

# GET /checklists/{id}/board
# Get the Board the Checklist is on
trello_get_board_checklist_is_on() {
    trello_request GET /checklists/{id}/board "$@"
}

# GET /checklists/{id}/cards
# Get the Card a Checklist is on
trello_get_card_checklist_is_on() {
    trello_request GET /checklists/{id}/cards "$@"
}

# GET /checklists/{id}/checkItems
# Get Checkitems on a Checklist
trello_get_checkitems_on_checklist() {
    trello_request GET /checklists/{id}/checkItems "$@"
}

# GET /checklists/{id}/checkItems/{idCheckItem}
# Get a Checkitem on a Checklist
trello_get_checkitem_on_checklist() {
    trello_request GET /checklists/{id}/checkItems/{idCheckItem} "$@"
}

# GET /checklists/{id}/{field}
# Get field on a Checklist
trello_get_field_on_checklist() {
    trello_request GET /checklists/{id}/{field} "$@"
}

# GET /customFields/{id}
# Get a Custom Field
trello_get_custom_field() {
    trello_request GET /customFields/{id} "$@"
}

# POST /customFields/{id}/options
# Add Option to Custom Field dropdown
# Add an option to a dropdown Custom Field
trello_add_option_to_custom_field_dropdown() {
    trello_request POST /customFields/{id}/options "$@"
}

# GET /customFields/{id}/options/{idCustomFieldOption}
# Get Option of Custom Field dropdown
# Retrieve a specific, existing Option on a given dropdown-type Custom Field
trello_get_option_custom_field_dropdown() {
    trello_request GET /customFields/{id}/options/{idCustomFieldOption} "$@"
}

# GET /enterprises/{id}
# Get an Enterprise
# Get an enterprise by its ID.
trello_get_enterprise() {
    trello_request GET /enterprises/{id} "$@"
}

# GET /enterprises/{id}/admins
# Get Enterprise admin Members
# Get an enterprise's admin members.
trello_get_enterprise_admin_members() {
    trello_request GET /enterprises/{id}/admins "$@"
}

# GET /enterprises/{id}/auditlog
# Get auditlog data for an Enterprise
# Returns an array of Actions related to the Enterprise object. Used for populating data sent to Googl
trello_get_auditlog_data_for_enterprise() {
    trello_request GET /enterprises/{id}/auditlog "$@"
}

# GET /enterprises/{id}/claimableOrganizations
# Get ClaimableOrganizations of an Enterprise
# Get the Workspaces that are claimable by the enterprise by ID. Can optionally query for workspaces b
trello_get_claimableorganizations_enterprise() {
    trello_request GET /enterprises/{id}/claimableOrganizations "$@"
}

# GET /enterprises/{id}/members
# Get Members of Enterprise
# Get the members of an enterprise.
trello_get_members_enterprise() {
    trello_request GET /enterprises/{id}/members "$@"
}

# GET /enterprises/{id}/members/{idMember}
# Get a Member of Enterprise
# Get a specific member of an enterprise by ID.
trello_get_member_enterprise() {
    trello_request GET /enterprises/{id}/members/{idMember} "$@"
}

# GET /enterprises/{id}/organizations
# Get Organizations of an Enterprise
# Get the organizations of an enterprise.
trello_get_organizations_enterprise() {
    trello_request GET /enterprises/{id}/organizations "$@"
}

# GET /enterprises/{id}/organizations/bulk/{idOrganizations}
# Bulk accept a set of organizations to an Enterprise.
# Accept an array of organizations to an enterprise.

# NOTE: For enterprises that have opted in to use
trello_bulk_accept_set_organizations_to_enterprise() {
    trello_request GET /enterprises/{id}/organizations/bulk/{idOrganizations} "$@"
}

# GET /enterprises/{id}/pendingOrganizations
# Get PendingOrganizations of an Enterprise
# Get the Workspaces that are pending for the enterprise by ID.
trello_get_pendingorganizations_enterprise() {
    trello_request GET /enterprises/{id}/pendingOrganizations "$@"
}

# GET /enterprises/{id}/signupUrl
# Get signupUrl for Enterprise
# Get the signup URL for an enterprise.
trello_get_signupurl_for_enterprise() {
    trello_request GET /enterprises/{id}/signupUrl "$@"
}

# GET /enterprises/{id}/transferrable/bulk/{idOrganizations}
# Get a bulk list of organizations that can be transferred to an enterprise.
# Get a list of organizations that can be transferred to an enterprise when given a bulk list of organ
trello_get_bulk_list_organizations_that_can_be_transferred_to_enterprise() {
    trello_request GET /enterprises/{id}/transferrable/bulk/{idOrganizations} "$@"
}

# GET /enterprises/{id}/transferrable/organization/{idOrganization}
# Get whether an organization can be transferred to an enterprise.
trello_get_whether_organization_can_be_transferred_to_enterprise() {
    trello_request GET /enterprises/{id}/transferrable/organization/{idOrganization} "$@"
}

# GET /labels/{id}
# Get a Label
# Get information about a single Label.
trello_get_label() {
    trello_request GET /labels/{id} "$@"
}

# GET /lists/{id}
# Get a List
# Get information about a List
trello_get_list() {
    trello_request GET /lists/{id} "$@"
}

# GET /lists/{id}/actions
# Get Actions for a List
# Get the Actions on a List
trello_get_actions_for_list() {
    trello_request GET /lists/{id}/actions "$@"
}

# GET /lists/{id}/board
# Get the Board a List is on
# Get the board a list is on
trello_get_board_list_is_on() {
    trello_request GET /lists/{id}/board "$@"
}

# GET /lists/{id}/cards
# Get Cards in a List
# List the cards in a list
trello_get_cards_in_list() {
    trello_request GET /lists/{id}/cards "$@"
}

# GET /members/{id}/actions
# Get a Member's Actions
# List the actions for a member
trello_get_members_actions() {
    trello_request GET /members/{id}/actions "$@"
}

# GET /members/{id}/boardBackgrounds
# Get Member's custom Board backgrounds
# Get a member's custom board backgrounds
trello_get_board_backgrounds() {
    trello_request GET /members/{id}/boardBackgrounds "$@"
}

# GET /members/{id}/boardBackgrounds/{idBackground}
# Get a boardBackground of a Member
# Get a member's board background
trello_get_boardbackground_member() {
    trello_request GET /members/{id}/boardBackgrounds/{idBackground} "$@"
}

# GET /members/{id}/boards
# Get Boards that Member belongs to
# Lists the boards that the user is a member of.
trello_get_boards_that_member_belongs_to() {
    trello_request GET /members/{id}/boards "$@"
}

# GET /members/{id}/boardsInvited
# Get Boards the Member has been invited to
# Get the boards the member has been invited to
trello_get_boards_member_has_been_invited_to() {
    trello_request GET /members/{id}/boardsInvited "$@"
}

# GET /members/{id}/boardStars
# Get a Member's boardStars
# List a member's board stars
trello_get_members_boardstars() {
    trello_request GET /members/{id}/boardStars "$@"
}

# GET /members/{id}/boardStars/{idStar}
# Get a boardStar of Member
# Get a specific boardStar
trello_get_boardstar_member() {
    trello_request GET /members/{id}/boardStars/{idStar} "$@"
}

# GET /members/{id}/cards
# Get Cards the Member is on
# Gets the cards a member is on
trello_get_cards_member_is_on() {
    trello_request GET /members/{id}/cards "$@"
}

# GET /members/{id}/customBoardBackgrounds
# Get a Member's custom Board Backgrounds
# Get a member's custom board backgrounds
trello_get_custom_board_backgrounds() {
    trello_request GET /members/{id}/customBoardBackgrounds "$@"
}

# GET /members/{id}/customBoardBackgrounds/{idBackground}
# Get custom Board Background of Member
# Get a specific custom board background
trello_get_custom_board_background_member() {
    trello_request GET /members/{id}/customBoardBackgrounds/{idBackground} "$@"
}

# GET /members/{id}/customEmoji
# Get a Member's customEmojis
# Get a Member's uploaded custom Emojis
trello_get_members_customemojis() {
    trello_request GET /members/{id}/customEmoji "$@"
}

# GET /members/{id}/customStickers
# Get Member's custom Stickers
# Get a Member's uploaded stickers
trello_get_members_custom_stickers() {
    trello_request GET /members/{id}/customStickers "$@"
}

# GET /members/{id}/customStickers/{idSticker}
# Get a Member's custom Sticker
trello_get_members_custom_sticker() {
    trello_request GET /members/{id}/customStickers/{idSticker} "$@"
}

# GET /members/{id}/{field}
# Get a field on a Member
# Get a particular property of a member
trello_get_field_on_member() {
    trello_request GET /members/{id}/{field} "$@"
}

# GET /members/{id}/notificationsChannelSettings
# Get a Member's notification channel settings
# Get a member's notification channel settings
trello_get_members_notification_channel_settings() {
    trello_request GET /members/{id}/notificationsChannelSettings "$@"
}

# GET /members/{id}/notificationsChannelSettings/{channel}
# Get blocked notification keys of Member on this channel
# Get blocked notification keys of Member on a specific channel
trello_get_blocked_notification_keys_member_on_this_channel() {
    trello_request GET /members/{id}/notificationsChannelSettings/{channel} "$@"
}

# GET /members/{id}/notifications
# Get Member's Notifications
# Get a member's notifications
trello_get_members_notifications() {
    trello_request GET /members/{id}/notifications "$@"
}

# GET /members/{id}/organizations
# Get Member's Organizations
# Get a member's Workspaces
trello_get_members_organizations() {
    trello_request GET /members/{id}/organizations "$@"
}

# GET /members/{id}/organizationsInvited
# Get Organizations a Member has been invited to
# Get a member's Workspaces they have been invited to
trello_get_organizations_member_has_been_invited_to() {
    trello_request GET /members/{id}/organizationsInvited "$@"
}

# GET /members/{id}/savedSearches
# Get Member's saved searched
# List the saved searches of a Member
trello_get_members_saved_searched() {
    trello_request GET /members/{id}/savedSearches "$@"
}

# GET /members/{id}/savedSearches/{idSearch}
# Get a saved search
trello_get_saved_search() {
    trello_request GET /members/{id}/savedSearches/{idSearch} "$@"
}

# GET /members/{id}/tokens
# Get Member's Tokens
# List a members app tokens
trello_get_members_tokens() {
    trello_request GET /members/{id}/tokens "$@"
}

# GET /members/{id}
# Get a Member
# Get a member
trello_get_member() {
    trello_request GET /members/{id} "$@"
}

# GET /notifications/{id}
# Get a Notification
trello_get_notification() {
    trello_request GET /notifications/{id} "$@"
}

# GET /notifications/{id}/board
# Get the Board a Notification is on
# Get the board a notification is associated with
trello_get_board_notification_is_on() {
    trello_request GET /notifications/{id}/board "$@"
}

# GET /notifications/{id}/card
# Get the Card a Notification is on
# Get the card a notification is associated with
trello_get_card_notification_is_on() {
    trello_request GET /notifications/{id}/card "$@"
}

# GET /notifications/{id}/{field}
# Get a field of a Notification
# Get a specific property of a notification
trello_get_field_notification() {
    trello_request GET /notifications/{id}/{field} "$@"
}

# GET /notifications/{id}/list
# Get the List a Notification is on
# Get the list a notification is associated with
trello_get_list_notification_is_on() {
    trello_request GET /notifications/{id}/list "$@"
}

# GET /notifications/{id}/memberCreator
# Get the Member who created the Notification
# Get the member who created the notification
trello_get_member_who_created_notification() {
    trello_request GET /notifications/{id}/memberCreator "$@"
}

# GET /notifications/{id}/organization
# Get a Notification's associated Organization
# Get the organization a notification is associated with
trello_get_notifications_associated_organization() {
    trello_request GET /notifications/{id}/organization "$@"
}

# GET /organizations/{id}
# Get an Organization
trello_get_organization() {
    trello_request GET /organizations/{id} "$@"
}

# GET /organizations/{id}/actions
# Get Actions for Organization
# List the actions on a Workspace
trello_get_actions_for_organization() {
    trello_request GET /organizations/{id}/actions "$@"
}

# GET /organizations/{id}/boards
# Get Boards in an Organization
# List the boards in a Workspace
trello_get_boards_in_organization() {
    trello_request GET /organizations/{id}/boards "$@"
}

# GET /organizations/{id}/exports
# Retrieve Organization's Exports
# Retrieve the exports that exist for the given organization
trello_retrieve_organizations_exports() {
    trello_request GET /organizations/{id}/exports "$@"
}

# GET /organizations/{id}/{field}
# Get field on Organization
trello_get_field_on_organization() {
    trello_request GET /organizations/{id}/{field} "$@"
}

# GET /organizations/{id}/members
# Get the Members of an Organization
# List the members in a Workspace
trello_get_members_organization() {
    trello_request GET /organizations/{id}/members "$@"
}

# GET /organizations/{id}/memberships
# Get Memberships of an Organization
# List the memberships of a Workspace
trello_get_memberships_organization() {
    trello_request GET /organizations/{id}/memberships "$@"
}

# GET /organizations/{id}/memberships/{idMembership}
# Get a Membership of an Organization
# Get a single Membership for an Organization
trello_get_membership_organization() {
    trello_request GET /organizations/{id}/memberships/{idMembership} "$@"
}

# GET /organizations/{id}/newBillableGuests/{idBoard}
# Get Organizations new billable guests
# Used to check whether the given board has new billable guests on it.
trello_get_organizations_new_billable_guests() {
    trello_request GET /organizations/{id}/newBillableGuests/{idBoard} "$@"
}

# GET /organizations/{id}/pluginData
# Get the pluginData Scoped to Organization
# Get organization scoped pluginData on this Workspace
trello_get_plugindata_scoped_to_organization() {
    trello_request GET /organizations/{id}/pluginData "$@"
}

# GET /organizations/{id}/tags
# Get Tags of an Organization
# List the organization's collections
trello_get_tags_organization() {
    trello_request GET /organizations/{id}/tags "$@"
}

# GET /plugins/{id}/
# Get a Plugin
# Get plugins
trello_get_plugin() {
    trello_request GET /plugins/{id}/ "$@"
}

# GET /plugins/{id}/compliance/memberPrivacy
# Get Plugin's Member privacy compliance
trello_get_plugins_member_privacy_compliance() {
    trello_request GET /plugins/{id}/compliance/memberPrivacy "$@"
}

# GET /search
# Search Trello
# Find what you're looking for in Trello
trello_search_trello() {
    trello_request GET /search "$@"
}

# GET /search/members/
# Search for Members
# Search for Trello members.
trello_search_for_members() {
    trello_request GET /search/members/ "$@"
}

# GET /tokens/{token}
# Get a Token
# Retrieve information about a token.
trello_get_token() {
    trello_request GET /tokens/{token} "$@"
}

# GET /tokens/{token}/member
# Get Token's Member
# Retrieve information about a token's owner by token.
trello_get_tokens_member() {
    trello_request GET /tokens/{token}/member "$@"
}

# GET /tokens/{token}/webhooks
# Get Webhooks for Token
# Retrieve all webhooks created with a Token.
trello_get_webhooks_for_token() {
    trello_request GET /tokens/{token}/webhooks "$@"
}

# GET /tokens/{token}/webhooks/{idWebhook}
# Get a Webhook belonging to a Token
# Retrieve a webhook created with a Token.
trello_get_webhook_belonging_to_token() {
    trello_request GET /tokens/{token}/webhooks/{idWebhook} "$@"
}

# GET /enterprises/{id}/members/query
# Get Users of an Enterprise
# Get an enterprise's users. You can choose to retrieve licensed members, board guests, etc. The respo
trello_get_users_enterprise() {
    trello_request GET /enterprises/{id}/members/query "$@"
}

# GET /webhooks/{id}
# Get a Webhook
# Get a webhook by ID. You must use the token query parameter and pass in the token the webhook was cr
trello_get_webhook() {
    trello_request GET /webhooks/{id} "$@"
}

# POST /members/{id}/avatar
# Create Avatar for Member
# Create a new avatar for a member
trello_create_avatar_for_member() {
    trello_request POST /members/{id}/avatar "$@"
}

# POST /members/{id}/customBoardBackgrounds
# Create a new custom Board Background
# Upload a new custom board background
trello_create_new_custom_board_background() {
    trello_request POST /members/{id}/customBoardBackgrounds "$@"
}

# GET /members/{id}/customEmoji/{idEmoji}
# Get a Member's custom Emoji
trello_get_members_custom_emoji() {
    trello_request GET /members/{id}/customEmoji/{idEmoji} "$@"
}

# GET /notifications/{id}/member
# Get the Member a Notification is about (not the creator)
# Get the member (not the creator) a notification is about
trello_get_member_notification_is_about_not_creator() {
    trello_request GET /notifications/{id}/member "$@"
}

# DELETE /organizations/{id}/members/{idMember}/all
# Remove a Member from an Organization and all Organization Boards
# Remove a member from a Workspace and from all Workspace boards
trello_remove_member_from_organization_and_all_organization_boards() {
    trello_request DELETE /organizations/{id}/members/{idMember}/all "$@"
}

# POST /actions/{idAction}/reactions
# Create Reaction for Action
# Adds a new reaction to an action
trello_create_reaction_for_action() {
    trello_request POST /actions/{idAction}/reactions "$@"
}

# POST /boards/
# Create a Board
# Create a new board.
trello_create_board() {
    trello_request POST /boards/ "$@"
}

# POST /boards/{id}/boardPlugins
# Enable a Power-Up on a Board
trello_enable_powerup_on_board() {
    trello_request POST /boards/{id}/boardPlugins "$@"
}

# POST /boards/{id}/calendarKey/generate
# Create a calendarKey for a Board
# Create a new board.
trello_create_calendarkey_for_board() {
    trello_request POST /boards/{id}/calendarKey/generate "$@"
}

# POST /boards/{id}/emailKey/generate
# Create a emailKey for a Board
trello_create_emailkey_for_board() {
    trello_request POST /boards/{id}/emailKey/generate "$@"
}

# POST /boards/{id}/idTags
# Create a Tag for a Board
trello_create_tag_for_board() {
    trello_request POST /boards/{id}/idTags "$@"
}

# POST /boards/{id}/labels
# Create a Label on a Board
# Create a new Label on a Board.
trello_create_label_on_board() {
    trello_request POST /boards/{id}/labels "$@"
}

# POST /boards/{id}/lists
# Create a List on a Board
# Create a new List on a Board.
trello_create_list_on_board() {
    trello_request POST /boards/{id}/lists "$@"
}

# POST /boards/{id}/markedAsViewed
# Mark Board as viewed
trello_mark_board_as_viewed() {
    trello_request POST /boards/{id}/markedAsViewed "$@"
}

# POST /cards
# Create a new Card
# Create a new card. Query parameters may also be replaced with a JSON request body instead.
trello_create_new_card() {
    trello_request POST /cards "$@"
}

trello_create_card() {
    trello_create_new_card "$@"
}

# POST /cards/{id}/actions/comments
# Add a new comment to a Card
# Add a new comment to a card
trello_add_new_comment_to_card() {
    trello_request POST /cards/{id}/actions/comments "$@"
}

# POST /cards/{id}/attachments
# Create Attachment On Card
# Create an Attachment to a Card. See https://glitch.com/~trello-attachments-api for code examples. Yo
trello_create_attachment_on_card() {
    trello_request POST /cards/{id}/attachments "$@"
}

# POST /cards/{id}/checklists
# Create Checklist on a Card
# Create a new checklist on a card
trello_create_checklist_on_card() {
    trello_request POST /cards/{id}/checklists "$@"
}

# POST /cards/{id}/idLabels
# Add a Label to a Card
# Add a label to a card
trello_add_label_to_card() {
    trello_request POST /cards/{id}/idLabels "$@"
}

# POST /cards/{id}/idMembers
# Add a Member to a Card
# Add a member to a card
trello_add_member_to_card() {
    trello_request POST /cards/{id}/idMembers "$@"
}

# POST /cards/{id}/labels
# Create a new Label on a Card
# Create a new label for the board and add it to the given card.
trello_create_new_label_on_card() {
    trello_request POST /cards/{id}/labels "$@"
}

# POST /cards/{id}/markAssociatedNotificationsRead
# Mark a Card's Notifications as read
# Mark notifications about this card as read
trello_mark_cards_notifications_as_read() {
    trello_request POST /cards/{id}/markAssociatedNotificationsRead "$@"
}

# POST /cards/{id}/stickers
# Add a Sticker to a Card
# Add a sticker to a card
trello_add_sticker_to_card() {
    trello_request POST /cards/{id}/stickers "$@"
}

# POST /checklists
# Create a Checklist
trello_create_checklist() {
    trello_request POST /checklists "$@"
}

# POST /checklists/{id}/checkItems
# Create Checkitem on Checklist
trello_create_checkitem_on_checklist() {
    trello_request POST /checklists/{id}/checkItems "$@"
}

# POST /customFields
# Create a new Custom Field on a Board
# Create a new Custom Field on a board.
trello_create_new_custom_field_on_board() {
    trello_request POST /customFields "$@"
}

# GET /customFields/{id}/options
# Get Options of Custom Field drop down
# Get the options of a drop down Custom Field
trello_get_options_custom_field_drop_down() {
    trello_request GET /customFields/{id}/options "$@"
}

# POST /enterprises/{id}/tokens
# Create an auth Token for an Enterprise.
trello_create_auth_token_for_enterprise() {
    trello_request POST /enterprises/{id}/tokens "$@"
}

# POST /labels
# Create a Label
# Create a new Label on a Board.
trello_create_label() {
    trello_request POST /labels "$@"
}

# POST /lists
# Create a new List
# Create a new List on a Board
trello_create_new_list() {
    trello_request POST /lists "$@"
}

# POST /lists/{id}/archiveAllCards
# Archive all Cards in List
# Archive all cards in a list
trello_archive_all_cards_in_list() {
    trello_request POST /lists/{id}/archiveAllCards "$@"
}

# POST /lists/{id}/moveAllCards
# Move all Cards in List
# Move all Cards in a List
trello_move_all_cards_in_list() {
    trello_request POST /lists/{id}/moveAllCards "$@"
}

# POST /members/{id}/boardBackgrounds
# Upload new boardBackground for Member
# Upload a new boardBackground
trello_upload_new_boardbackground_for_member() {
    trello_request POST /members/{id}/boardBackgrounds "$@"
}

# POST /members/{id}/boardStars
# Create Star for Board
# Star a new board on behalf of a Member
trello_create_star_for_board() {
    trello_request POST /members/{id}/boardStars "$@"
}

# POST /members/{id}/customEmoji
# Create custom Emoji for Member
# Create a new custom Emoji
trello_create_custom_emoji_for_member() {
    trello_request POST /members/{id}/customEmoji "$@"
}

# POST /members/{id}/customStickers
# Create custom Sticker for Member
# Upload a new custom sticker
trello_create_custom_sticker_for_member() {
    trello_request POST /members/{id}/customStickers "$@"
}

# POST /members/{id}/oneTimeMessagesDismissed
# Dismiss a message for Member
# Dismiss a message
trello_dismiss_message_for_member() {
    trello_request POST /members/{id}/oneTimeMessagesDismissed "$@"
}

# POST /members/{id}/savedSearches
# Create saved Search for Member
# Create a saved search
trello_create_saved_search_for_member() {
    trello_request POST /members/{id}/savedSearches "$@"
}

# POST /notifications/all/read
# Mark all Notifications as read
# Mark all notifications as read
trello_mark_all_notifications_as_read() {
    trello_request POST /notifications/all/read "$@"
}

# POST /organizations
# Create a new Organization
# Create a new Workspace
trello_create_new_organization() {
    trello_request POST /organizations "$@"
}

# POST /organizations/{id}/exports
# Create Export for Organizations
# Kick off CSV export for an organization
trello_create_export_for_organizations() {
    trello_request POST /organizations/{id}/exports "$@"
}

# POST /organizations/{id}/logo
# Update logo for an Organization
# Set the logo image for a Workspace
trello_update_logo_for_organization() {
    trello_request POST /organizations/{id}/logo "$@"
}

# POST /organizations/{id}/tags
# Create a Tag in Organization
# Create a Tag in an Organization
trello_create_tag_in_organization() {
    trello_request POST /organizations/{id}/tags "$@"
}

# POST /plugins/{idPlugin}/listing
# Create a Listing for Plugin
# Create a new listing for a given locale for your Power-Up
trello_create_listing_for_plugin() {
    trello_request POST /plugins/{idPlugin}/listing "$@"
}

# POST /tokens/{token}/webhooks
# Create Webhooks for Token
# Create a new webhook for a Token.
trello_create_webhooks_for_token() {
    trello_request POST /tokens/{token}/webhooks "$@"
}

# POST /webhooks/
# Create a Webhook
# Create a new webhook.
trello_create_webhook() {
    trello_request POST /webhooks/ "$@"
}

# PUT /actions/{id}
# Update an Action
# Update a specific Action. Only comment actions can be updated. Used to edit the content of a comment
trello_update_action() {
    trello_request PUT /actions/{id} "$@"
}

# PUT /actions/{id}/text
# Update a Comment Action
# Update a comment action
trello_update_comment_action() {
    trello_request PUT /actions/{id}/text "$@"
}

# PUT /boards/{id}
# Update a Board
# Update an existing board by id
trello_update_board() {
    trello_request PUT /boards/{id} "$@"
}

# PUT /boards/{id}/members
# Invite Member to Board via email
# Invite a Member to a Board via their email address.
trello_invite_member_to_board_via_email() {
    trello_request PUT /boards/{id}/members "$@"
}

# PUT /boards/{id}/members/{idMember}
# Add a Member to a Board
# Add a member to the board.
trello_add_member_to_board() {
    trello_request PUT /boards/{id}/members/{idMember} "$@"
}

# PUT /boards/{id}/memberships/{idMembership}
# Update Membership of Member on a Board
# Update an existing board by id
trello_update_membership_member_on_board() {
    trello_request PUT /boards/{id}/memberships/{idMembership} "$@"
}

# PUT /boards/{id}/myPrefs/showSidebar
# Update showSidebar Pref on a Board
trello_update_showsidebar_pref_on_board() {
    trello_request PUT /boards/{id}/myPrefs/showSidebar "$@"
}

# PUT /boards/{id}/myPrefs/showSidebarActivity
# Update showSidebarActivity Pref on a Board
trello_update_showsidebaractivity_pref_on_board() {
    trello_request PUT /boards/{id}/myPrefs/showSidebarActivity "$@"
}

# PUT /boards/{id}/myPrefs/showSidebarBoardActions
# Update showSidebarBoardActions Pref on a Board
trello_update_showsidebarboardactions_pref_on_board() {
    trello_request PUT /boards/{id}/myPrefs/showSidebarBoardActions "$@"
}

# PUT /boards/{id}/myPrefs/showSidebarMembers
# Update showSidebarMembers Pref on a Board
trello_update_showsidebarmembers_pref_on_board() {
    trello_request PUT /boards/{id}/myPrefs/showSidebarMembers "$@"
}

# PUT /boards/{id}/myPrefs/emailPosition
# Update emailPosition Pref on a Board
trello_update_emailposition_pref_on_board() {
    trello_request PUT /boards/{id}/myPrefs/emailPosition "$@"
}

# PUT /boards/{id}/myPrefs/idEmailList
# Update idEmailList Pref on a Board
# Change the default list that email-to-board cards are created in.
trello_update_idemaillist_pref_on_board() {
    trello_request PUT /boards/{id}/myPrefs/idEmailList "$@"
}

# PUT /cards/{id}
# Update a Card
# Update a card. Query parameters may also be replaced with a JSON request body instead.
trello_update_card() {
    trello_request PUT /cards/{id} "$@"
}

# PUT /cards/{id}/actions/{idAction}/comments
# Update Comment Action on a Card
# Update an existing comment
trello_update_comment_action_on_card() {
    trello_request PUT /cards/{id}/actions/{idAction}/comments "$@"
}

# PUT /cards/{id}/checkItem/{idCheckItem}
# Update a checkItem on a Card
# Update an item in a checklist on a card.
trello_update_checkitem_on_card() {
    trello_request PUT /cards/{id}/checkItem/{idCheckItem} "$@"
}

# PUT /cards/{id}/stickers/{idSticker}
# Update a Sticker on a Card
# Update a sticker on a card
trello_update_sticker_on_card() {
    trello_request PUT /cards/{id}/stickers/{idSticker} "$@"
}

# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}
# Update Checkitem on Checklist on Card
# Update an item in a checklist on a card.
trello_update_checkitem_on_checklist_on_card() {
    trello_request PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem} "$@"
}

# PUT /cards/{idCard}/customField/{idCustomField}/item
# Update Custom Field item on Card
# Setting, updating, and removing the value for a Custom Field on a card. For more details on updating
trello_update_custom_field_item_on_card() {
    trello_request PUT /cards/{idCard}/customField/{idCustomField}/item "$@"
}

# PUT /cards/{idCard}/customFields
# Update Multiple Custom Field items on Card
# Setting, updating, and removing the values for multiple Custom Fields on a card. For more details on
trello_update_multiple_custom_field_items_on_card() {
    trello_request PUT /cards/{idCard}/customFields "$@"
}

# PUT /checklists/{id}/{field}
# Update field on a Checklist
trello_update_field_on_checklist() {
    trello_request PUT /checklists/{id}/{field} "$@"
}

# PUT /checklists/{id}
# Update a Checklist
# Update an existing checklist.
trello_update_checklist() {
    trello_request PUT /checklists/{id} "$@"
}

# PUT /customFields/{id}
# Update a Custom Field definition
# Update a Custom Field definition.
trello_update_custom_field_definition() {
    trello_request PUT /customFields/{id} "$@"
}

# PUT /enterprises/{id}/admins/{idMember}
# Update Member to be admin of Enterprise
# Make Member an admin of Enterprise.

# NOTE: This endpoint is not available to enterprises that have
trello_update_member_to_be_admin_enterprise() {
    trello_request PUT /enterprises/{id}/admins/{idMember} "$@"
}

# PUT /enterprises/{id}/enterpriseJoinRequest/bulk
# Decline enterpriseJoinRequests from one organization or a bulk list of organizations.
# Decline enterpriseJoinRequests from one organization or bulk amount of organizations
trello_decline_enterprisejoinrequests_from_one_organization_or_bulk_list_organizations() {
    trello_request PUT /enterprises/{id}/enterpriseJoinRequest/bulk "$@"
}

# PUT /enterprises/{id}/members/{idMember}/licensed
# Update a Member's licensed status
# This endpoint is used to update whether the provided Member should use one of the Enterprise's avail
trello_update_members_licensed_status() {
    trello_request PUT /enterprises/{id}/members/{idMember}/licensed "$@"
}

# PUT /enterprises/{id}/organizations
# Transfer an Organization to an Enterprise.
# Transfer an organization to an enterprise.

# NOTE: For enterprises that have opted in to user manage
trello_transfer_organization_to_enterprise() {
    trello_request PUT /enterprises/{id}/organizations "$@"
}

# PUT /lists/{id}/idBoard
# Move List to Board
# Move a List to a different Board
trello_move_list_to_board() {
    trello_request PUT /lists/{id}/idBoard "$@"
}

# PUT /labels/{id}
# Update a Label
# Update a label by ID.
trello_update_label() {
    trello_request PUT /labels/{id} "$@"
}

# PUT /labels/{id}/{field}
# Update a field on a label
# Update a field on a label.
trello_update_field_on_label() {
    trello_request PUT /labels/{id}/{field} "$@"
}

# PUT /lists/{id}
# Update a List
# Update the properties of a List
trello_update_list() {
    trello_request PUT /lists/{id} "$@"
}

# PUT /lists/{id}/closed
# Archive or unarchive a list
trello_archive_or_unarchive_list() {
    trello_request PUT /lists/{id}/closed "$@"
}

# PUT /lists/{id}/{field}
# Update a field on a List
# Rename a list
trello_update_field_on_list() {
    trello_request PUT /lists/{id}/{field} "$@"
}

# PUT /members/{id}
# Update a Member
trello_update_member() {
    trello_request PUT /members/{id} "$@"
}

# PUT /members/{id}/boardBackgrounds/{idBackground}
# Update a Member's custom Board background
# Update a board background
trello_update_members_custom_board_background() {
    trello_request PUT /members/{id}/boardBackgrounds/{idBackground} "$@"
}

# PUT /members/{id}/boardStars/{idStar}
# Update the position of a boardStar of Member
# Update the position of a starred board
trello_update_position_boardstar_member() {
    trello_request PUT /members/{id}/boardStars/{idStar} "$@"
}

# PUT /members/{id}/customBoardBackgrounds/{idBackground}
# Update custom Board Background of Member
# Update a specific custom board background
trello_update_custom_board_background_member() {
    trello_request PUT /members/{id}/customBoardBackgrounds/{idBackground} "$@"
}

# PUT /members/{id}/notificationsChannelSettings
# Update blocked notification keys of Member on a channel
# Update blocked notification keys of Member on a specific channel
trello_update_blocked_notification_keys_member() {
    trello_request PUT /members/{id}/notificationsChannelSettings "$@"
}

# PUT /members/{id}/notificationsChannelSettings/{channel}
# Update blocked notification keys of Member on a channel
# Update blocked notification keys of Member on a specific channel
trello_update_blocked_notification_keys_member_channel() {
    trello_request PUT /members/{id}/notificationsChannelSettings/{channel} "$@"
}

# PUT /members/{id}/notificationsChannelSettings/{channel}/{blockedKeys}
# Update blocked notification keys of Member on a channel
# Update blocked notification keys of Member on a specific channel
trello_update_blocked_notification_keys_member_on_channel() {
    trello_request PUT /members/{id}/notificationsChannelSettings/{channel}/{blockedKeys} "$@"
}

# PUT /members/{id}/savedSearches/{idSearch}
# Update a saved search
trello_update_saved_search() {
    trello_request PUT /members/{id}/savedSearches/{idSearch} "$@"
}

# PUT /notifications/{id}
# Update a Notification's read status
# Update the read status of a notification
trello_update_notification() {
    trello_request PUT /notifications/{id} "$@"
}

# PUT /notifications/{id}/unread
# Update Notification's read status
trello_mark_notification_unread() {
    trello_request PUT /notifications/{id}/unread "$@"
}

# PUT /organizations/{id}
# Update an Organization
# Update an organization
trello_update_organization() {
    trello_request PUT /organizations/{id} "$@"
}

# PUT /organizations/{id}/members
# Update an Organization's Members
trello_update_organizations_members() {
    trello_request PUT /organizations/{id}/members "$@"
}

# PUT /organizations/{id}/members/{idMember}
# Update a Member of an Organization
# Add a member to a Workspace or update their member type.
trello_update_member_organization() {
    trello_request PUT /organizations/{id}/members/{idMember} "$@"
}

# PUT /organizations/{id}/members/{idMember}/deactivated
# Deactivate or reactivate a member of an Organization
# Deactivate or reactivate a member of a Workspace
trello_deactivate_or_reactivate_member_organization() {
    trello_request PUT /organizations/{id}/members/{idMember}/deactivated "$@"
}

# PUT /plugins/{id}/
# Update a Plugin
trello_update_plugin() {
    trello_request PUT /plugins/{id}/ "$@"
}

# PUT /plugins/{idPlugin}/listings/{idListing}
# Updating Plugin's Listing
# Update an existing listing for your Power-Up
trello_updating_plugins_listing() {
    trello_request PUT /plugins/{idPlugin}/listings/{idListing} "$@"
}

# PUT /webhooks/{id}
# Update a Webhook
# Update a webhook by ID.
trello_update_webhook() {
    trello_request PUT /webhooks/{id} "$@"
}

# PUT /tokens/{token}/webhooks/{idWebhook}
# Update a Webhook created by Token
trello_update_webhook_created_by_token() {
    trello_request PUT /tokens/{token}/webhooks/{idWebhook} "$@"
}

# GET /webhooks/{id}/{field}
# Get a field on a Webhook
trello_get_field_on_webhook() {
    trello_request GET /webhooks/{id}/{field} "$@"
}

# Total functions: 254
# This file is auto-generated - do not edit manually
