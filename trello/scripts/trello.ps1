# Trello REST API - Consolidated PowerShell Functions
# This script contains all endpoint functions for the Trello REST API
# Dot-source this file: . ./trello.ps1
#
# Environment variables required:
#   TRELLO_API_KEY - Your Trello API key
#   TRELLO_TOKEN   - Your Trello API token
#
# Examples:
#   $env:TRELLO_API_KEY = "your_key"
#   $env:TRELLO_TOKEN = "your_token"
#   Invoke-GetAction -Id abc123
#   Invoke-CreateNewCard -IdList xyz -Name "My Card"

$ErrorActionPreference = 'Stop'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Assert-TrelloAuthentication {
    [CmdletBinding()]
    param()
    
    if ([string]::IsNullOrEmpty($env:TRELLO_API_KEY)) {
        throw "TRELLO_API_KEY environment variable not set"
    }
    if ([string]::IsNullOrEmpty($env:TRELLO_TOKEN)) {
        throw "TRELLO_TOKEN environment variable not set"
    }
}

function ConvertTo-TrelloEncodedValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [object]$Value
    )

    [System.Uri]::EscapeDataString([string]$Value)
}

function ConvertTo-TrelloApiParameterName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    if ($Name.Length -le 1) {
        return $Name.ToLowerInvariant()
    }

    $Name.Substring(0, 1).ToLowerInvariant() + $Name.Substring(1)
}

function Add-TrelloParameterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary]$Map,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [object]$Value
    )

    $normalizedName = $Name.TrimStart('-')
    if ([string]::IsNullOrWhiteSpace($normalizedName)) {
        return
    }

    $Map[$normalizedName] = $Value
}

function ConvertFrom-TrelloRemainingArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object[]]$Params
    )

    $map = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::OrdinalIgnoreCase)
    if ($null -eq $Params) {
        return $map
    }

    for ($i = 0; $i -lt $Params.Count; $i++) {
        $item = $Params[$i]
        if ($item -is [hashtable]) {
            foreach ($key in $item.Keys) {
                Add-TrelloParameterValue -Map $map -Name ([string]$key) -Value $item[$key]
            }
            continue
        }

        if (($item -is [string]) -and $item.StartsWith('-')) {
            $name = $item.TrimStart('-')
            $value = $true
            if (($i + 1) -lt $Params.Count) {
                $next = $Params[$i + 1]
                if (-not (($next -is [string]) -and $next.StartsWith('-'))) {
                    $value = $next
                    $i++
                }
            }
            Add-TrelloParameterValue -Map $map -Name $name -Value $value
            continue
        }

        if (-not $map.Contains('__Positionals')) {
            $map['__Positionals'] = [System.Collections.Generic.List[object]]::new()
        }
        $map['__Positionals'].Add($item)
    }

    $map
}

function Add-TrelloQueryPairs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Pairs,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [object]$Value
    )

    if ($null -eq $Value) {
        return
    }

    if (($Value -is [System.Collections.IEnumerable]) -and
        -not ($Value -is [string]) -and
        -not ($Value -is [hashtable])) {
        foreach ($entry in $Value) {
            Add-TrelloQueryPairs -Pairs $Pairs -Name $Name -Value $entry
        }
        return
    }

    $Pairs.Add(("{0}={1}" -f (ConvertTo-TrelloEncodedValue $Name), (ConvertTo-TrelloEncodedValue $Value)))
}

function Add-TrelloQueryString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Pairs,

        [Parameter(Mandatory=$false)]
        [object]$Query
    )

    if ($null -eq $Query) {
        return
    }

    if ($Query -is [hashtable]) {
        foreach ($key in $Query.Keys) {
            Add-TrelloQueryPairs -Pairs $Pairs -Name ([string]$key) -Value $Query[$key]
        }
        return
    }

    foreach ($part in ([string]$Query -split '&')) {
        if ([string]::IsNullOrWhiteSpace($part)) {
            continue
        }

        $name, $value = $part -split '=', 2
        if ($null -eq $value) {
            $value = ''
        }

        Add-TrelloQueryPairs `
            -Pairs $Pairs `
            -Name ([System.Uri]::UnescapeDataString($name)) `
            -Value ([System.Uri]::UnescapeDataString($value))
    }
}

function Resolve-TrelloPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary]$ParameterMap
    )

    $usedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $resolvedPath = [regex]::Replace($Path, '\$\{([^}]+)\}|\{([^}]+)\}', {
        param($Match)

        $name = if ($Match.Groups[1].Success) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
        if (-not $ParameterMap.Contains($name)) {
            throw "Missing required Trello path parameter '$name' for path '$Path'"
        }

        [void]$usedNames.Add($name)
        ConvertTo-TrelloEncodedValue $ParameterMap[$name]
    })

    [pscustomobject]@{
        Path = $resolvedPath
        UsedParameterNames = $usedNames
    }
}

function Invoke-TrelloRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('GET','POST','PUT','DELETE','PATCH')]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [object]$Query,
        
        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false)]
        [object[]]$Params
    )
    
    Assert-TrelloAuthentication
    
    $baseUrl = "https://api.trello.com/1"
    $parameterMap = ConvertFrom-TrelloRemainingArguments -Params $Params
    if ($null -ne $Parameters) {
        foreach ($key in $Parameters.Keys) {
            Add-TrelloParameterValue -Map $parameterMap -Name ([string]$key) -Value $Parameters[$key]
        }
    }

    if ($parameterMap.Contains('Query') -and $null -eq $Query) {
        $Query = $parameterMap['Query']
    }
    if ($parameterMap.Contains('Body') -and $null -eq $Body) {
        $Body = $parameterMap['Body']
    }

    $resolvedPath = Resolve-TrelloPath -Path $Path -ParameterMap $parameterMap
    
    $queryPairs = [System.Collections.Generic.List[string]]::new()
    Add-TrelloQueryPairs -Pairs $queryPairs -Name 'key' -Value $env:TRELLO_API_KEY
    Add-TrelloQueryPairs -Pairs $queryPairs -Name 'token' -Value $env:TRELLO_TOKEN
    Add-TrelloQueryString -Pairs $queryPairs -Query $Query
    
    foreach ($key in $parameterMap.Keys) {
        if ($key -in @('Query', 'Body', 'Parameters', 'Params', '__Positionals')) {
            continue
        }
        if ($resolvedPath.UsedParameterNames.Contains($key)) {
            continue
        }

        Add-TrelloQueryPairs -Pairs $queryPairs -Name (ConvertTo-TrelloApiParameterName $key) -Value $parameterMap[$key]
    }

    $uriBuilder = [System.UriBuilder]::new("${baseUrl}$($resolvedPath.Path)")
    $uriBuilder.Query = [string]::Join('&', $queryPairs)
    $url = $uriBuilder.Uri.AbsoluteUri
    
    $requestParams = @{
        Uri = $url
        Method = $Method
    }
    
    if ($null -ne $Body) {
        $requestParams['Headers'] = @{ 'Content-Type' = 'application/json' }
        if ($Body -is [string]) {
            $requestParams['Body'] = $Body
        } else {
            $requestParams['Body'] = $Body | ConvertTo-Json -Depth 20
        }
    }
    
    Invoke-WebRequest @requestParams
}

# ============================================================================
# ENDPOINT FUNCTIONS
# ============================================================================

function Invoke-GetApplicationsComplianceData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/applications/{key}/compliance' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetChecklistsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/checklists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveMemberFromBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/boards/{id}/members/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddMemberVoteToCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/membersVoted' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/actions/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteActionsReaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/actions/{idAction}/reactions/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/boards/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DisablePowerupOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/boards/{id}/boardPlugins/{idPlugin}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteCommentOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/actions/{idAction}/comments' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteCheckitemOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/checkItem/{idCheckItem}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteChecklistOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/checklists/{idChecklist}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveLabelFromCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/idLabels/{idLabel}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveMembersVoteOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/membersVoted/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteStickerOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/stickers/{idSticker}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/checklists/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteCheckitemFromChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/checklists/{id}/checkItems/{idCheckItem}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteCustomFieldDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/customFields/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteOptionCustomFieldDropdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/customFields/{id}/options/{idCustomFieldOption}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteOrganizationFromEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/enterprises/{id}/organizations/{idOrg}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveMemberFromCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/idMembers/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/labels/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteMembersCustomBoardBackground {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/members/{id}/boardBackgrounds/{idBackground}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteStarForBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/members/{id}/boardStars/{idStar}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteCustomBoardBackgroundMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/members/{id}/customBoardBackgrounds/{idBackground}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteMembersCustomSticker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/members/{id}/customStickers/{idSticker}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteSavedSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/members/{id}/savedSearches/{idSearch}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteLogoForOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}/logo' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveMemberFromOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}/members/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveAssociatedGoogleAppsDomainFromWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}/prefs/associatedDomain' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteEmailDomainRestrictionOnWhoCanBeInvitedToWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}/prefs/orgInviteRestrict' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteOrganizationsTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}/tags/{idTag}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/tokens/{token}/' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteWebhookCreatedByToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/tokens/{token}/webhooks/{idWebhook}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/webhooks/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeleteAttachmentOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/cards/{id}/attachments/{idAttachment}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-ListAvailableEmoji {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/emoji' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeactivateMemberEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/enterprises/{id}/members/{idMember}/deactivated' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveMemberAsAdminFromEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/enterprises/{id}/admins/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardForAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/board' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCardForAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/card' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetSpecificFieldOnAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetListForAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/list' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMemberAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/member' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMemberCreatorAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/memberCreator' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOrganizationAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{id}/organization' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetActionsReactions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{idAction}/reactions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetActionsReaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{idAction}/reactions/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-ListActionsSummaryReactions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/actions/{idAction}/reactionsSummary' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-BatchRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/batch' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetPowerupsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/plugins' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetActionsBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{boardId}/actions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetEnabledPowerupsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/boardPlugins' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardstarsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{boardId}/boardStars' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCardsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/cards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFilteredCardsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/cards/{filter}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCustomFieldsForBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/customFields' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetLabelsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/labels' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetListsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/lists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFilteredListsOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/lists/{filter}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/members' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembershipsBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/boards/{id}/memberships' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetActionsOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/actions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetAttachmentsOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/attachments' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetAttachmentOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/attachments/{idAttachment}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardCardIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/board' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCheckitemOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/checkItem/{idCheckItem}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCheckitemsOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/checkItemStates' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetChecklistsOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/checklists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCustomFieldItemsForCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/customFieldItems' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetListCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/list' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/members' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersWhoHaveVotedOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/membersVoted' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetPlugindataOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/pluginData' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetStickersOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/stickers' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetStickerOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/cards/{id}/stickers/{idSticker}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/checklists/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardChecklistIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/checklists/{id}/board' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCardChecklistIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/checklists/{id}/cards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCheckitemsOnChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/checklists/{id}/checkItems' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCheckitemOnChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/checklists/{id}/checkItems/{idCheckItem}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldOnChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/checklists/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCustomField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/customFields/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddOptionToCustomFieldDropdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/customFields/{id}/options' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOptionCustomFieldDropdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/customFields/{id}/options/{idCustomFieldOption}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetEnterpriseAdminMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/admins' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetAuditlogDataForEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/auditlog' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetClaimableorganizationsEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/claimableOrganizations' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/members' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMemberEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/members/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOrganizationsEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/organizations' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-BulkAcceptSetOrganizationsToEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/organizations/bulk/{idOrganizations}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetPendingorganizationsEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/pendingOrganizations' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetSignupurlForEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/signupUrl' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBulkListOrganizationsThatCanBeTransferredToEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/transferrable/bulk/{idOrganizations}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetWhetherOrganizationCanBeTransferredToEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/transferrable/organization/{idOrganization}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/labels/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/lists/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetActionsForList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/lists/{id}/actions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardListIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/lists/{id}/board' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCardsInList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/lists/{id}/cards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/actions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardBackgrounds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/boardBackgrounds' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardbackgroundMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/boardBackgrounds/{idBackground}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardsThatMemberBelongsTo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/boards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardsMemberHasBeenInvitedTo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/boardsInvited' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersBoardstars {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/boardStars' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardstarMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/boardStars/{idStar}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCardsMemberIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/cards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCustomBoardBackgrounds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/customBoardBackgrounds' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCustomBoardBackgroundMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/customBoardBackgrounds/{idBackground}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersCustomemojis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/customEmoji' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersCustomStickers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/customStickers' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersCustomSticker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/customStickers/{idSticker}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldOnMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersNotificationChannelSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/notificationsChannelSettings' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBlockedNotificationKeysMemberOnThisChannel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/notificationsChannelSettings/{channel}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersNotifications {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/notifications' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersOrganizations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/organizations' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOrganizationsMemberHasBeenInvitedTo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/organizationsInvited' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersSavedSearched {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/savedSearches' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetSavedSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/savedSearches/{idSearch}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/tokens' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardNotificationIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/board' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetCardNotificationIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/card' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetListNotificationIsOn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/list' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMemberWhoCreatedNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/memberCreator' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetNotificationsAssociatedOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/organization' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetActionsForOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/actions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetBoardsInOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/boards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RetrieveOrganizationsExports {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/exports' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldOnOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/members' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembershipsOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/memberships' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembershipOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/memberships/{idMembership}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOrganizationsNewBillableGuests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/newBillableGuests/{idBoard}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetPlugindataScopedToOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/pluginData' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetTagsOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/organizations/{id}/tags' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/plugins/{id}/' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetPluginsMemberPrivacyCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/plugins/{id}/compliance/memberPrivacy' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-SearchTrello {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/search' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-SearchForMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/search/members/' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/tokens/{token}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetTokensMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/tokens/{token}/member' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetWebhooksForToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/tokens/{token}/webhooks' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetWebhookBelongingToToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/tokens/{token}/webhooks/{idWebhook}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetUsersEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/enterprises/{id}/members/query' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/webhooks/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateAvatarForMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/avatar' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateNewCustomBoardBackground {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/customBoardBackgrounds' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMembersCustomEmoji {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/members/{id}/customEmoji/{idEmoji}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetMemberNotificationIsAboutNotCreator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/notifications/{id}/member' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-RemoveMemberFromOrganizationAndAllOrganizationBoards {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method DELETE -Path '/organizations/{id}/members/{idMember}/all' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateReactionForAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/actions/{idAction}/reactions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-EnablePowerupOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/boardPlugins' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateCalendarkeyForBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/calendarKey/generate' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateEmailkeyForBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/emailKey/generate' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateTagForBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/idTags' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateLabelOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/labels' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateListOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/lists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-MarkBoardAsViewed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/boards/{id}/markedAsViewed' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateNewCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddNewCommentToCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/actions/comments' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateAttachmentOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/attachments' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateChecklistOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/checklists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddLabelToCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/idLabels' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddMemberToCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/idMembers' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateNewLabelOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/labels' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-MarkCardsNotificationsAsRead {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/markAssociatedNotificationsRead' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddStickerToCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/cards/{id}/stickers' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/checklists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateCheckitemOnChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/checklists/{id}/checkItems' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateNewCustomFieldOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/customFields' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetOptionsCustomFieldDropDown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/customFields/{id}/options' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateAuthTokenForEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/enterprises/{id}/tokens' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/labels' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateNewList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/lists' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-ArchiveAllCardsInList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/lists/{id}/archiveAllCards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-MoveAllCardsInList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/lists/{id}/moveAllCards' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UploadNewBoardbackgroundForMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/boardBackgrounds' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateStarForBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/boardStars' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateCustomEmojiForMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/customEmoji' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateCustomStickerForMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/customStickers' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DismissMessageForMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/oneTimeMessagesDismissed' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateSavedSearchForMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/members/{id}/savedSearches' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-MarkAllNotificationsAsRead {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/notifications/all/read' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateNewOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/organizations' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateExportForOrganizations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/organizations/{id}/exports' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateLogoForOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/organizations/{id}/logo' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateTagInOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/organizations/{id}/tags' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateListingForPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/plugins/{idPlugin}/listing' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateWebhooksForToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/tokens/{token}/webhooks' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-CreateWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method POST -Path '/webhooks/' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/actions/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCommentAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/actions/{id}/text' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-InviteMemberToBoardViaEmail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/members' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-AddMemberToBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/members/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMembershipMemberOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/memberships/{idMembership}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateShowsidebarPrefOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/myPrefs/showSidebar' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateShowsidebaractivityPrefOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/myPrefs/showSidebarActivity' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateShowsidebarboardactionsPrefOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/myPrefs/showSidebarBoardActions' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateShowsidebarmembersPrefOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/myPrefs/showSidebarMembers' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateEmailpositionPrefOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/myPrefs/emailPosition' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateIdemaillistPrefOnBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/boards/{id}/myPrefs/idEmailList' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCommentActionOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{id}/actions/{idAction}/comments' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCheckitemOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{id}/checkItem/{idCheckItem}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateStickerOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{id}/stickers/{idSticker}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCheckitemOnChecklistOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCustomFieldItemOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{idCard}/customField/{idCustomField}/item' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMultipleCustomFieldItemsOnCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/cards/{idCard}/customFields' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateFieldOnChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/checklists/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateChecklist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/checklists/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCustomFieldDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/customFields/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMemberToBeAdminEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/enterprises/{id}/admins/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeclineEnterprisejoinrequestsFromOneOrganizationOrBulkListOrganizations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/enterprises/{id}/enterpriseJoinRequest/bulk' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMembersLicensedStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/enterprises/{id}/members/{idMember}/licensed' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-TransferOrganizationToEnterprise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/enterprises/{id}/organizations' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-MoveListToBoard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/lists/{id}/idBoard' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/labels/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateFieldOnLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/labels/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/lists/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-ArchiveOrUnarchiveList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/lists/{id}/closed' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateFieldOnList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/lists/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMembersCustomBoardBackground {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/boardBackgrounds/{idBackground}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdatePositionBoardstarMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/boardStars/{idStar}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateCustomBoardBackgroundMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/customBoardBackgrounds/{idBackground}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateBlockedNotificationKeysMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/notificationsChannelSettings' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateBlockedNotificationKeysMemberChannel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/notificationsChannelSettings/{channel}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateBlockedNotificationKeysMemberOnChannel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/notificationsChannelSettings/{channel}/{blockedKeys}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateSavedSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/members/{id}/savedSearches/{idSearch}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/notifications/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-MarkNotificationUnread {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/notifications/{id}/unread' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/organizations/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateOrganizationsMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/organizations/{id}/members' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateMemberOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/organizations/{id}/members/{idMember}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-DeactivateOrReactivateMemberOrganization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/organizations/{id}/members/{idMember}/deactivated' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdatePlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/plugins/{id}/' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdatingPluginsListing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/plugins/{idPlugin}/listings/{idListing}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/webhooks/{id}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-UpdateWebhookCreatedByToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method PUT -Path '/tokens/{token}/webhooks/{idWebhook}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

function Invoke-GetFieldOnWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Query,

        [Parameter(Mandatory=$false)]
        [object]$Body,

        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [object[]]$Params
    )
    Invoke-TrelloRequest -Method GET -Path '/webhooks/{id}/{field}' -Query $Query -Body $Body -Parameters $Parameters -Params $Params
}

# Total functions: 254
# This file is auto-generated - do not edit manually
