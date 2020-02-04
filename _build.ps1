$BuildPath = Join-Path $PSScriptRoot 'Bin'

Remove-Item "$BuildPath\*" -Recurse

Merge-Script -Script (Join-Path $PSScriptRoot 'nightly_backup.ps1') -Bundle -OutputPath $BuildPath

Copy-Item (Join-Path $PSScriptRoot '7zip') -Recurse -Force -Destination $BuildPath

$7zArgs = @(
    "a"; # Create an archive.
    "$BuildPath\nighty_backup.zip";
    "-tzip";
    "$BuildPath\*";
)

& $7zip @7zArgs