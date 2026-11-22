$ErrorActionPreference = 'Stop'
$addons = Split-Path -Parent $PSScriptRoot
$source = Join-Path $addons 'TradeSkillMaster_AppHelper\AppData.lua'
$destination = Join-Path $addons 'PriceCheckReplyGuild_TSMData'
$pattern = 'LoadData\("AUCTIONDB_NON_COMMODITY_(?:DATA|SCAN_STAT)",\s*"(?<realm>[^"\\]+)",\s*\[\[return\s*\{\s*downloadTime\s*=\s*(?<timestamp>\d+)'
$updates = @{}
foreach ($line in [IO.File]::ReadLines($source)) {
    $match = [regex]::Match($line, $pattern)
    if (!$match.Success) { continue }
    $realm = $match.Groups['realm'].Value.ToLowerInvariant()
    $timestamp = [long]$match.Groups['timestamp'].Value
    if ($timestamp -gt $updates[$realm]) { $updates[$realm] = $timestamp }
}
if (!$updates.Count) { throw 'TSM AppHelper contains no realm update timestamps.' }

$interface = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'PriceCheckReplyGuild.toc') -TotalCount 1
$toc = @($interface, '## Title: PriceCheck Reply Guild - TSM Realm Data', '## DefaultState: enabled', 'RealmUpdates.lua')
$lua = @('PriceCheckReplyGuild_TSMRealmUpdates = {')
foreach ($realm in ($updates.Keys | Sort-Object)) {
    $lua += '    ["{0}"] = {1},' -f $realm, $updates[$realm]
}
$lua += '}'

New-Item -ItemType Directory -Path $destination -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllLines((Join-Path $destination 'RealmUpdates.lua'), [string[]]$lua, $utf8)
[IO.File]::WriteAllLines((Join-Path $destination 'PriceCheckReplyGuild_TSMData.toc'), [string[]]$toc, $utf8)
Write-Output "Imported TSM timestamps for $($updates.Count) realm entries."
