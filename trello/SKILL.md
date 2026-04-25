---
name: "trello"
description: "Trello REST API unified skill with 256 endpoints"
---

# Trello REST API

Complete reference for interacting with the Trello REST API. Contains all 256 endpoints organized by resource.

## Resources

- [Actions](resources/actions.md) - 16 endpoints
- [Applications](resources/applications.md) - 1 endpoint
- [Batch](resources/batch.md) - 1 endpoint
- [Boards](resources/boards.md) - 35 endpoints
- [Cards](resources/cards.md) - 39 endpoints
- [Checklists](resources/checklists.md) - 12 endpoints
- [Custom Fields](resources/custom-fields.md) - 24 endpoints
- [Emoji](resources/emoji.md) - 1 endpoint
- [Enterprises](resources/enterprises.md) - 21 endpoints
- [Labels](resources/labels.md) - 5 endpoints
- [Lists](resources/lists.md) - 11 endpoints
- [Members](resources/members.md) - 33 endpoints
- [Notifications](resources/notifications.md) - 11 endpoints
- [Organizations](resources/organizations.md) - 26 endpoints
- [Plugins](resources/plugins.md) - 5 endpoints
- [Search](resources/search.md) - 2 endpoints
- [Tokens](resources/tokens.md) - 8 endpoints
- [Webhooks](resources/webhooks.md) - 5 endpoints

## Glossary

- **Board** - the top-level Trello workspace for a project. Lists and cards live inside a board. When the user names a board, resolve the board first. See Trello 101: [What is a board?](https://trello.com/guide/trello-101#what-is-a-board)
- **List** - a column inside a board, such as To Do, Doing, or Done. Lists belong to one board. See Trello 101: [What is a list?](https://trello.com/guide/trello-101#what-is-a-list)
- **Card** - an individual task/item. Cards belong to a board and usually to a list. See Trello 101: [What is a card?](https://trello.com/guide/trello-101#what-is-a-card)
- **Member** - a Trello user/person. Do not use member endpoints just because a board belongs to the current user; use them only for user/person questions or when a board-discovery endpoint explicitly requires `me`.
- **Organization/Workspace** - a grouping above boards. Use it only when the user asks about a workspace/org or board discovery needs that scope.
- **Board menu** - board-level controls and activity context. Use board/menu concepts for board settings, permissions, Power-Ups, automation, and board activity. See Trello 101: [What is the board menu?](https://trello.com/guide/trello-101#what-is-the-board-menu)

## Official Trello Guides

- [Trello 101: Learn Trello board basics](https://trello.com/guide/trello-101) - official concept guide for boards, lists, cards, and the board menu.
- [Create your first project](https://trello.com/guide/create-project) - official onboarding flow for turning a project into a Trello board.
  - [Create a board](https://trello.com/guide/create-project#create-a-board).
  - [Customize your board](https://trello.com/guide/create-project#customize-your-board).
  - [Start collaborating](https://trello.com/guide/create-project#start-collaborating).
  - [Build a workflow](https://trello.com/guide/create-project#build-a-workflow).
  - [Add tasks and to-dos](https://trello.com/guide/create-project#add-tasks-and-to-dos).
- [Onboard your team to Trello](https://trello.com/guide/onboard-team) - official collaboration setup guide.
  - [Understand Workspaces](https://trello.com/guide/onboard-team#what-is-a-workspace).
  - [Set up a few boards](https://trello.com/guide/onboard-team#set-up-a-few-boards).
  - [Apply onboarding success tips](https://trello.com/guide/onboard-team#tips-for-onboarding-success).
  - [Gain cross-team perspective](https://trello.com/guide/onboard-team#gain-cross-team-perspective).
- [Integrate Trello with other apps](https://trello.com/guide/integrate-apps) - official integration guide.
  - [Improve team communication](https://trello.com/guide/integrate-apps#improve-team-communication).
  - [Turn emails into action items](https://trello.com/guide/integrate-apps#turn-emails-into-real-action-items).
  - [Use Power-Ups](https://trello.com/guide/integrate-apps#do-more-with-power-ups).
  - [Connect tools such as Slack, Confluence, Google Drive, Jira, and Gmail](https://trello.com/guide/integrate-apps#improve-team-communication).
- [Powerful collaboration features](https://trello.com/guide/collaboration-features) - official collaboration feature guide.
  - [Invite and assign members](https://trello.com/guide/collaboration-features#invite-and-assign-members).
  - [Use comments, mentions, and card activity](https://trello.com/guide/collaboration-features#comments-mentions-and-activity).
  - [Add due dates, labels, attachments, and checklists](https://trello.com/guide/collaboration-features#due-dates-labels-attachments-and-checklists).
  - [Track shared work on cards and boards](https://trello.com/guide/collaboration-features#track-shared-work).
- [Activate different views](https://trello.com/guide/activate-views) - official guide for board views.
  - [Board view](https://trello.com/guide/activate-views#board-view).
  - [Table view](https://trello.com/guide/activate-views#table-view).
  - [Calendar view](https://trello.com/guide/activate-views#calendar-view).
  - [Timeline view](https://trello.com/guide/activate-views#timeline-view).
  - [Dashboard view](https://trello.com/guide/activate-views#dashboard-view).
  - [Map view](https://trello.com/guide/activate-views#map-view).
  - [Workspace views](https://trello.com/guide/activate-views#workspace-views).
- [Automate anything in Trello](https://trello.com/guide/automate-anything) - official automation guide.
  - [Intro to automation](https://trello.com/guide/automate-anything#intro-to-automation).
  - [Getting started with automation](https://trello.com/guide/automate-anything#getting-started-with-automation).
  - [Rule-based automation](https://trello.com/guide/automate-anything#rule-based-automation).
  - [Card and board buttons](https://trello.com/guide/automate-anything#card-and-board-buttons).
  - [Calendar and due date commands](https://trello.com/guide/automate-anything#calendar-and-due-date-commands).
  - [Automations for email and integrations](https://trello.com/guide/automate-anything#automations-for-email-and-integrations).
- [Set permissions and admin controls](https://trello.com/guide/permissions-controls) - official permissions/admin guide.
  - [Workspace administration](https://trello.com/guide/permissions-controls#workspace-administration).
  - [Member and guest permissions](https://trello.com/guide/permissions-controls#member-and-guest-permissions).
  - [User management with Trello Premium](https://trello.com/guide/permissions-controls#user-management-with-trello-premium).
  - [Board privacy and visibility controls](https://trello.com/guide/permissions-controls#setting-board-permissions).
- [Trello top tips and tricks](https://trello.com/guide/tips-tricks) - official tips guide.
  - [Card covers](https://trello.com/guide/tips-tricks#card-covers).
  - [Card separators](https://trello.com/guide/tips-tricks#card-separator).
  - [Emoji reactions](https://trello.com/guide/tips-tricks#emoji-reactions).
  - [Stickers](https://trello.com/guide/tips-tricks#stickers).
  - [Confetti celebrations](https://trello.com/guide/tips-tricks#confetti-celebration).
  - [Mark as done](https://trello.com/guide/tips-tricks#mark-as-done).
  - [Shortcuts](https://trello.com/guide/tips-tricks#shortcuts).

## Common Workflows

### Read a card from a named board

Do not start by searching members. Treat this as a board/card lookup:

1. Resolve the board from the user's board name, URL, or ID.
   - If the user gave a board ID or Trello board URL, use it directly with the Boards endpoints.
   - If the user gave only a board name, list accessible boards through the Boards flow and match by `name` or `url`.
2. Use the resolved board ID with `GET /boards/{id}/cards`.
   - Bash: `get_cards_on_board id=<board_id> fields=name,desc,url,idList,closed`
   - PowerShell: `Invoke-GetCardsOnBoard -Id <board_id> -Query "fields=name,desc,url,idList,closed"`
3. Find the requested card by exact or close `name` match.
4. Read details with `GET /cards/{id}` only after the card ID is known.
   - Bash: `get_card id=<card_id> fields=name,desc,url,idBoard,idList,closed`
   - PowerShell: `Invoke-GetCard -Id <card_id> -Query "fields=name,desc,url,idBoard,idList,closed"`

### Choose the right resource first

- Board name, board URL, cards on a board, lists on a board: start with **Boards**.
- Card URL, card ID, comments, attachments, checklist items on a card: start with **Cards**.
- Checklist ID or checklist items independent of a card: start with **Checklists**.
- Person/user questions, member permissions, invited boards, member profile data: start with **Members**.
- Workspace/org questions: start with **Organizations**.

## Scripts

Two consolidated scripts provide endpoint functions using shared helper functions for authentication and HTTP requests:

### Bash (Linux/macOS)

```bash
export TRELLO_API_KEY="your_api_key"
export TRELLO_TOKEN="your_api_token"
source scripts/trello.sh

# Make API calls using endpoint functions
get_card id=abc123
create_new_card idList=xyz123 '{"name":"Card Name","desc":"Description"}'
```

**Bash Helper Functions:**
- `trello_require_authentication()` - Validates that TRELLO_API_KEY and TRELLO_TOKEN are set
- `trello_request(METHOD, PATH, [QUERY], [BODY])` - Makes authenticated requests to the Trello API

### PowerShell (Windows)

```powershell
$env:TRELLO_API_KEY = "your_api_key"
$env:TRELLO_TOKEN = "your_api_token"
. ./scripts/trello.ps1

# Make API calls using endpoint functions
Invoke-GetCard -Id abc123 -Query "fields=name,desc"
Invoke-CreateNewCard -Query "idList=xyz123" -Body '{"name":"Card Name","desc":"Description"}'
```

**PowerShell Helper Functions:**
- `Assert-TrelloAuthentication` - Validates that TRELLO_API_KEY and TRELLO_TOKEN environment variables are set
- `Invoke-TrelloRequest(Method, Path, [Query], [Body])` - Makes authenticated requests to the Trello API

## Authentication

All functions require environment variables to be set:
- `TRELLO_API_KEY` - Your Trello API key (get from https://trello.com/app-key)
- `TRELLO_TOKEN` - Your Trello API token (generate from https://trello.com/app-key)

The helper functions automatically validate these credentials before making requests.

## Endpoint Patterns

Endpoints follow standard REST patterns:
- **GET** - Retrieve resource
- **POST** - Create resource
- **PUT** - Update resource
- **DELETE** - Delete resource
