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
#   Invoke-TrelloGetAction -Id abc123
#   Invoke-TrelloCreateCard -IdList xyz -Name "My Card"

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

function Invoke-TrelloGetApplicationsComplianceData {
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

function Invoke-TrelloGetChecklistsOnBoard {
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

function Invoke-TrelloRemoveMemberFromBoard {
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

function Invoke-TrelloAddMemberVoteToCard {
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

function Invoke-TrelloDeleteAction {
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

function Invoke-TrelloDeleteActionsReaction {
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

function Invoke-TrelloDeleteBoard {
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

function Invoke-TrelloDisablePowerupOnBoard {
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

function Invoke-TrelloDeleteCard {
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

function Invoke-TrelloDeleteCommentOnCard {
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

function Invoke-TrelloDeleteCheckitemOnCard {
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

function Invoke-TrelloDeleteChecklistOnCard {
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

function Invoke-TrelloRemoveLabelFromCard {
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

function Invoke-TrelloRemoveMembersVoteOnCard {
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

function Invoke-TrelloDeleteStickerOnCard {
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

function Invoke-TrelloDeleteChecklist {
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

function Invoke-TrelloDeleteCheckitemFromChecklist {
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

function Invoke-TrelloDeleteCustomFieldDefinition {
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

function Invoke-TrelloDeleteOptionCustomFieldDropdown {
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

function Invoke-TrelloDeleteOrganizationFromEnterprise {
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

function Invoke-TrelloRemoveMemberFromCard {
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

function Invoke-TrelloDeleteLabel {
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

function Invoke-TrelloDeleteMembersCustomBoardBackground {
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

function Invoke-TrelloDeleteStarForBoard {
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

function Invoke-TrelloDeleteCustomBoardBackgroundMember {
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

function Invoke-TrelloDeleteMembersCustomSticker {
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

function Invoke-TrelloDeleteSavedSearch {
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

function Invoke-TrelloDeleteOrganization {
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

function Invoke-TrelloDeleteLogoForOrganization {
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

function Invoke-TrelloRemoveMemberFromOrganization {
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

function Invoke-TrelloRemoveAssociatedGoogleAppsDomainFromWorkspace {
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

function Invoke-TrelloDeleteEmailDomainRestrictionOnWhoCanBeInvitedToWorkspace {
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

function Invoke-TrelloDeleteOrganizationsTag {
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

function Invoke-TrelloDeleteToken {
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

function Invoke-TrelloDeleteWebhookCreatedByToken {
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

function Invoke-TrelloDeleteWebhook {
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

function Invoke-TrelloDeleteAttachmentOnCard {
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

function Invoke-TrelloListAvailableEmoji {
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

function Invoke-TrelloDeactivateMemberEnterprise {
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

function Invoke-TrelloRemoveMemberAsAdminFromEnterprise {
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

function Invoke-TrelloGetAction {
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

function Invoke-TrelloGetBoardForAction {
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

function Invoke-TrelloGetCardForAction {
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

function Invoke-TrelloGetSpecificFieldOnAction {
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

function Invoke-TrelloGetListForAction {
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

function Invoke-TrelloGetMemberAction {
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

function Invoke-TrelloGetMemberCreatorAction {
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

function Invoke-TrelloGetOrganizationAction {
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

function Invoke-TrelloGetActionsReactions {
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

function Invoke-TrelloGetActionsReaction {
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

function Invoke-TrelloListActionsSummaryReactions {
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

function Invoke-TrelloBatchRequests {
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

function Invoke-TrelloGetPowerupsOnBoard {
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

function Invoke-TrelloGetBoard {
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

function Invoke-TrelloGetActionsBoard {
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

function Invoke-TrelloGetEnabledPowerupsOnBoard {
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

function Invoke-TrelloGetBoardstarsOnBoard {
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

function Invoke-TrelloGetCardsOnBoard {
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

function Invoke-TrelloGetFilteredCardsOnBoard {
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

function Invoke-TrelloGetCustomFieldsForBoard {
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

function Invoke-TrelloGetFieldOnBoard {
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

function Invoke-TrelloGetLabelsOnBoard {
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

function Invoke-TrelloGetListsOnBoard {
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

function Invoke-TrelloGetFilteredListsOnBoard {
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

function Invoke-TrelloGetMembersBoard {
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

function Invoke-TrelloGetMembershipsBoard {
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

function Invoke-TrelloGetCard {
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

function Invoke-TrelloGetActionsOnCard {
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

function Invoke-TrelloGetAttachmentsOnCard {
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

function Invoke-TrelloGetAttachmentOnCard {
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

function Invoke-TrelloGetBoardCardIsOn {
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

function Invoke-TrelloGetCheckitemOnCard {
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

function Invoke-TrelloGetCheckitemsOnCard {
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

function Invoke-TrelloGetChecklistsOnCard {
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

function Invoke-TrelloGetCustomFieldItemsForCard {
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

function Invoke-TrelloGetFieldOnCard {
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

function Invoke-TrelloGetListCard {
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

function Invoke-TrelloGetMembersCard {
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

function Invoke-TrelloGetMembersWhoHaveVotedOnCard {
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

function Invoke-TrelloGetPlugindataOnCard {
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

function Invoke-TrelloGetStickersOnCard {
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

function Invoke-TrelloGetStickerOnCard {
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

function Invoke-TrelloGetChecklist {
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

function Invoke-TrelloGetBoardChecklistIsOn {
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

function Invoke-TrelloGetCardChecklistIsOn {
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

function Invoke-TrelloGetCheckitemsOnChecklist {
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

function Invoke-TrelloGetCheckitemOnChecklist {
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

function Invoke-TrelloGetFieldOnChecklist {
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

function Invoke-TrelloGetCustomField {
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

function Invoke-TrelloAddOptionToCustomFieldDropdown {
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

function Invoke-TrelloGetOptionCustomFieldDropdown {
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

function Invoke-TrelloGetEnterprise {
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

function Invoke-TrelloGetEnterpriseAdminMembers {
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

function Invoke-TrelloGetAuditlogDataForEnterprise {
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

function Invoke-TrelloGetClaimableorganizationsEnterprise {
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

function Invoke-TrelloGetMembersEnterprise {
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

function Invoke-TrelloGetMemberEnterprise {
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

function Invoke-TrelloGetOrganizationsEnterprise {
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

function Invoke-TrelloBulkAcceptSetOrganizationsToEnterprise {
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

function Invoke-TrelloGetPendingorganizationsEnterprise {
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

function Invoke-TrelloGetSignupurlForEnterprise {
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

function Invoke-TrelloGetBulkListOrganizationsThatCanBeTransferredToEnterprise {
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

function Invoke-TrelloGetWhetherOrganizationCanBeTransferredToEnterprise {
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

function Invoke-TrelloGetLabel {
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

function Invoke-TrelloGetList {
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

function Invoke-TrelloGetActionsForList {
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

function Invoke-TrelloGetBoardListIsOn {
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

function Invoke-TrelloGetCardsInList {
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

function Invoke-TrelloGetMembersActions {
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

function Invoke-TrelloGetBoardBackgrounds {
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

function Invoke-TrelloGetBoardbackgroundMember {
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

function Invoke-TrelloGetBoardsThatMemberBelongsTo {
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

function Invoke-TrelloGetBoardsMemberHasBeenInvitedTo {
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

function Invoke-TrelloGetMembersBoardstars {
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

function Invoke-TrelloGetBoardstarMember {
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

function Invoke-TrelloGetCardsMemberIsOn {
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

function Invoke-TrelloGetCustomBoardBackgrounds {
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

function Invoke-TrelloGetCustomBoardBackgroundMember {
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

function Invoke-TrelloGetMembersCustomemojis {
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

function Invoke-TrelloGetMembersCustomStickers {
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

function Invoke-TrelloGetMembersCustomSticker {
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

function Invoke-TrelloGetFieldOnMember {
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

function Invoke-TrelloGetMembersNotificationChannelSettings {
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

function Invoke-TrelloGetBlockedNotificationKeysMemberOnThisChannel {
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

function Invoke-TrelloGetMembersNotifications {
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

function Invoke-TrelloGetMembersOrganizations {
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

function Invoke-TrelloGetOrganizationsMemberHasBeenInvitedTo {
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

function Invoke-TrelloGetMembersSavedSearched {
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

function Invoke-TrelloGetSavedSearch {
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

function Invoke-TrelloGetMembersTokens {
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

function Invoke-TrelloGetMember {
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

function Invoke-TrelloGetNotification {
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

function Invoke-TrelloGetBoardNotificationIsOn {
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

function Invoke-TrelloGetCardNotificationIsOn {
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

function Invoke-TrelloGetFieldNotification {
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

function Invoke-TrelloGetListNotificationIsOn {
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

function Invoke-TrelloGetMemberWhoCreatedNotification {
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

function Invoke-TrelloGetNotificationsAssociatedOrganization {
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

function Invoke-TrelloGetOrganization {
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

function Invoke-TrelloGetActionsForOrganization {
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

function Invoke-TrelloGetBoardsInOrganization {
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

function Invoke-TrelloRetrieveOrganizationsExports {
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

function Invoke-TrelloGetFieldOnOrganization {
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

function Invoke-TrelloGetMembersOrganization {
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

function Invoke-TrelloGetMembershipsOrganization {
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

function Invoke-TrelloGetMembershipOrganization {
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

function Invoke-TrelloGetOrganizationsNewBillableGuests {
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

function Invoke-TrelloGetPlugindataScopedToOrganization {
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

function Invoke-TrelloGetTagsOrganization {
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

function Invoke-TrelloGetPlugin {
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

function Invoke-TrelloGetPluginsMemberPrivacyCompliance {
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

function Invoke-TrelloSearchTrello {
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

function Invoke-TrelloSearchForMembers {
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

function Invoke-TrelloGetToken {
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

function Invoke-TrelloGetTokensMember {
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

function Invoke-TrelloGetWebhooksForToken {
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

function Invoke-TrelloGetWebhookBelongingToToken {
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

function Invoke-TrelloGetUsersEnterprise {
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

function Invoke-TrelloGetWebhook {
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

function Invoke-TrelloCreateAvatarForMember {
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

function Invoke-TrelloCreateNewCustomBoardBackground {
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

function Invoke-TrelloGetMembersCustomEmoji {
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

function Invoke-TrelloGetMemberNotificationIsAboutNotCreator {
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

function Invoke-TrelloRemoveMemberFromOrganizationAndAllOrganizationBoards {
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

function Invoke-TrelloCreateReactionForAction {
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

function Invoke-TrelloCreateBoard {
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

function Invoke-TrelloEnablePowerupOnBoard {
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

function Invoke-TrelloCreateCalendarkeyForBoard {
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

function Invoke-TrelloCreateEmailkeyForBoard {
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

function Invoke-TrelloCreateTagForBoard {
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

function Invoke-TrelloCreateLabelOnBoard {
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

function Invoke-TrelloCreateListOnBoard {
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

function Invoke-TrelloMarkBoardAsViewed {
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

function Invoke-TrelloCreateNewCard {
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

function Invoke-TrelloAddNewCommentToCard {
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

function Invoke-TrelloCreateAttachmentOnCard {
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

function Invoke-TrelloCreateChecklistOnCard {
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

function Invoke-TrelloAddLabelToCard {
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

function Invoke-TrelloAddMemberToCard {
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

function Invoke-TrelloCreateNewLabelOnCard {
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

function Invoke-TrelloMarkCardsNotificationsAsRead {
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

function Invoke-TrelloAddStickerToCard {
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

function Invoke-TrelloCreateChecklist {
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

function Invoke-TrelloCreateCheckitemOnChecklist {
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

function Invoke-TrelloCreateNewCustomFieldOnBoard {
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

function Invoke-TrelloGetOptionsCustomFieldDropDown {
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

function Invoke-TrelloCreateAuthTokenForEnterprise {
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

function Invoke-TrelloCreateLabel {
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

function Invoke-TrelloCreateNewList {
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

function Invoke-TrelloArchiveAllCardsInList {
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

function Invoke-TrelloMoveAllCardsInList {
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

function Invoke-TrelloUploadNewBoardbackgroundForMember {
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

function Invoke-TrelloCreateStarForBoard {
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

function Invoke-TrelloCreateCustomEmojiForMember {
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

function Invoke-TrelloCreateCustomStickerForMember {
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

function Invoke-TrelloDismissMessageForMember {
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

function Invoke-TrelloCreateSavedSearchForMember {
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

function Invoke-TrelloMarkAllNotificationsAsRead {
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

function Invoke-TrelloCreateNewOrganization {
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

function Invoke-TrelloCreateExportForOrganizations {
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

function Invoke-TrelloUpdateLogoForOrganization {
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

function Invoke-TrelloCreateTagInOrganization {
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

function Invoke-TrelloCreateListingForPlugin {
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

function Invoke-TrelloCreateWebhooksForToken {
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

function Invoke-TrelloCreateWebhook {
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

function Invoke-TrelloUpdateAction {
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

function Invoke-TrelloUpdateCommentAction {
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

function Invoke-TrelloUpdateBoard {
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

function Invoke-TrelloInviteMemberToBoardViaEmail {
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

function Invoke-TrelloAddMemberToBoard {
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

function Invoke-TrelloUpdateMembershipMemberOnBoard {
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

function Invoke-TrelloUpdateShowsidebarPrefOnBoard {
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

function Invoke-TrelloUpdateShowsidebaractivityPrefOnBoard {
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

function Invoke-TrelloUpdateShowsidebarboardactionsPrefOnBoard {
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

function Invoke-TrelloUpdateShowsidebarmembersPrefOnBoard {
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

function Invoke-TrelloUpdateEmailpositionPrefOnBoard {
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

function Invoke-TrelloUpdateIdemaillistPrefOnBoard {
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

function Invoke-TrelloUpdateCard {
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

function Invoke-TrelloUpdateCommentActionOnCard {
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

function Invoke-TrelloUpdateCheckitemOnCard {
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

function Invoke-TrelloUpdateStickerOnCard {
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

function Invoke-TrelloUpdateCheckitemOnChecklistOnCard {
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

function Invoke-TrelloUpdateCustomFieldItemOnCard {
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

function Invoke-TrelloUpdateMultipleCustomFieldItemsOnCard {
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

function Invoke-TrelloUpdateFieldOnChecklist {
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

function Invoke-TrelloUpdateChecklist {
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

function Invoke-TrelloUpdateCustomFieldDefinition {
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

function Invoke-TrelloUpdateMemberToBeAdminEnterprise {
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

function Invoke-TrelloDeclineEnterprisejoinrequestsFromOneOrganizationOrBulkListOrganizations {
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

function Invoke-TrelloUpdateMembersLicensedStatus {
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

function Invoke-TrelloTransferOrganizationToEnterprise {
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

function Invoke-TrelloMoveListToBoard {
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

function Invoke-TrelloUpdateLabel {
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

function Invoke-TrelloUpdateFieldOnLabel {
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

function Invoke-TrelloUpdateList {
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

function Invoke-TrelloArchiveOrUnarchiveList {
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

function Invoke-TrelloUpdateFieldOnList {
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

function Invoke-TrelloUpdateMember {
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

function Invoke-TrelloUpdateMembersCustomBoardBackground {
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

function Invoke-TrelloUpdatePositionBoardstarMember {
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

function Invoke-TrelloUpdateCustomBoardBackgroundMember {
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

function Invoke-TrelloUpdateBlockedNotificationKeysMember {
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

function Invoke-TrelloUpdateBlockedNotificationKeysMemberChannel {
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

function Invoke-TrelloUpdateBlockedNotificationKeysMemberOnChannel {
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

function Invoke-TrelloUpdateSavedSearch {
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

function Invoke-TrelloUpdateNotification {
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

function Invoke-TrelloMarkNotificationUnread {
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

function Invoke-TrelloUpdateOrganization {
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

function Invoke-TrelloUpdateOrganizationsMembers {
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

function Invoke-TrelloUpdateMemberOrganization {
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

function Invoke-TrelloDeactivateOrReactivateMemberOrganization {
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

function Invoke-TrelloUpdatePlugin {
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

function Invoke-TrelloUpdatingPluginsListing {
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

function Invoke-TrelloUpdateWebhook {
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

function Invoke-TrelloUpdateWebhookCreatedByToken {
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

function Invoke-TrelloGetFieldOnWebhook {
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

Set-Alias -Name Invoke-TrelloCreateCard -Value Invoke-TrelloCreateNewCard


# Total functions: 254
# This file is auto-generated - do not edit manually
