$BuildPath = Join-Path $PSScriptRoot 'Bin'

Remove-Item "$BuildPath\*" -Recurse

Merge-Script -Script (Join-Path $PSScriptRoot 'main.ps1') -Bundle -OutputPath "$BuildPath"

Move-Item (Join-Path $BuildPath 'main.ps1') -Destination "$BuildPath\nightly_backup.ps1"
Copy-Item (Join-Path $PSScriptRoot '7zip') -Recurse -Force -Destination $BuildPath

echo "PowerShell.exe -ExecutionPolicy Bypass -Command `"& '%~dpn0.ps1'`"" >> "$BuildPath\nightly_backup.cmd"

$7zArgs = @(
    "a"; # Create an archive.
    "$BuildPath\nighty_backup.zip";
    "-tzip";
    "$BuildPath\*";
)

& $7zip @7zArgs