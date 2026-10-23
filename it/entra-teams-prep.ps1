#Requires -Version 7
<#
.SYNOPSIS
  One-shot tenant prep for Agentic Enterprise Linux Teams gateway.

.DESCRIPTION
  Run in Azure Cloud Shell or on a Windows admin box as Global Admin /
  Application Administrator + Teams Administrator.

  Creates (or reuses) the service principal for the AEL multi-tenant app,
  grants the *minimum* Graph/Teams permissions, optionally creates an
  "AEL Ops" team + "alerts" channel, and prints cloud-init keys.

  Does NOT embed a client secret. AEL uses device-code / admin-consent
  on first boot. This script only makes IT's click-path boring.

.NOTES
  Replace $AelAppId with the public app ID when it exists.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AelAppId,

    [string]$TeamName = "AEL Ops",
    [string]$ChannelName = "alerts",
    [switch]$SkipTeamCreate
)

$ErrorActionPreference = "Stop"

$scopes = @(
    "Application.ReadWrite.All",
    "AppRoleAssignment.ReadWrite.All",
    "Team.ReadBasic.All",
    "Team.Create",
    "Channel.ReadBasic.All",
    "Channel.Create",
    "Organization.Read.All"
)

Write-Host "Connecting to Graph (browser consent for *this admin session* only)..."
Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null

$org = Get-MgOrganization | Select-Object -First 1
$tenantId = $org.Id
Write-Host "Tenant: $($org.DisplayName)  $tenantId"

$sp = Get-MgServicePrincipal -Filter "appId eq '$AelAppId'" -ErrorAction SilentlyContinue
if (-not $sp) {
    Write-Host "Creating service principal for $AelAppId"
    $sp = New-MgServicePrincipal -AppId $AelAppId
} else {
    Write-Host "Service principal already present: $($sp.Id)"
}

# Resource: Microsoft Graph
$graph = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
# ChannelMessage.Send (application) and ChannelMessage.Read.Group are the intended floor.
# Exact app-role IDs vary; resolve by value:
$wanted = @("ChannelMessage.Send", "Team.ReadBasic.All")
$roles = $graph.AppRoles | Where-Object { $_.Value -in $wanted -and $_.AllowedMemberTypes -contains "Application" }
foreach ($role in $roles) {
    $exists = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id |
        Where-Object { $_.AppRoleId -eq $role.Id }
    if (-not $exists) {
        New-MgServicePrincipalAppRoleAssignment `
            -ServicePrincipalId $sp.Id `
            -PrincipalId $sp.Id `
            -ResourceId $graph.Id `
            -AppRoleId $role.Id | Out-Null
        Write-Host "Granted $($role.Value)"
    }
}

$teamId = $null
$channelId = $null
if (-not $SkipTeamCreate) {
    $team = Get-MgGroup -Filter "displayName eq '$TeamName' and resourceProvisioningOptions/Any(x:x eq 'Team')" |
        Select-Object -First 1
    if (-not $team) {
        Write-Warning "Team '$TeamName' not found. Create it in the Teams admin centre (locked tenants block Graph Team.Create), then re-run."
    } else {
        $teamId = $team.Id
        $ch = Get-MgTeamChannel -TeamId $teamId | Where-Object { $_.DisplayName -eq $ChannelName } | Select-Object -First 1
        if (-not $ch) {
            try {
                $ch = New-MgTeamChannel -TeamId $teamId -DisplayName $ChannelName -MembershipType "standard"
            } catch {
                Write-Warning "Could not create channel: $($_.Exception.Message)"
            }
        }
        if ($ch) { $channelId = $ch.Id }
    }
}

Write-Host ""
Write-Host "==== paste into AEL first-run / cloud-init ===="
Write-Host "ael.entra.tenant: $tenantId"
if ($teamId)    { Write-Host "ael.teams.team: $teamId" }
if ($channelId) { Write-Host "ael.teams.channel: $channelId" }
Write-Host "ael.entra.app: $AelAppId"
Write-Host "==== end ===="
Write-Host "If team/channel are empty: create them in Teams, then re-run with -SkipTeamCreate:`$false after the team exists,"
Write-Host "or pass IDs by creating the team manually (IT-preferred in locked-down tenants)."
