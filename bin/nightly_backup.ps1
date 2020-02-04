function Backup-Full
{
	Param (
		[Parameter(Mandatory = $true)]
		[String]$InputPath,
		[Parameter(Mandatory = $true)]
		[String]$OutputFile
	)	
	$7zArgs = @(
		"a"; # Create an archive.
		"$OutputFile";
		"-t7z"; # Use the 7z format.
		"-mx=7"; # Use a level 7 "high" compression.
		"-xr!thumbs.db"; # Exclude thumbs.db files wherever they are found.
		"-xr!*.log"; # Exclude all *.log files as well.
		#"-xr-@`"`"$excludesFile`"`""; # Exclude all paths in my excludes.txt file.
		#"-ir-@`"`"$includesFile`"`""; # Include all paths in my includes.txt file.
		"$InputPath"; # Output file path (a *.7z file).
	)
	

	
	& $7zip @7zArgs | Tee-Object -FilePath "$OutputFile.log"
	if ($LASTEXITCODE -gt 1) # Ignores warnings which use exit code 1.
	{
		throw "7zip failed with exit code $LASTEXITCODE"
	}
	
}

function Backup-Diff
{
	Param (
		[Parameter(Mandatory = $true)]
		[String]$InputPath,
		[Parameter(Mandatory = $true)]
		[String]$FullBackupPath,
		[Parameter(Mandatory = $true)]
		[String]$OutputFile
	)
	
	$7zArgs = @(
		"u"; # Update an archive. Slightly confusing since we'll be saving those updates to a new archive file.
		"`"$FullBackupPath`""; # Path of the full backup we are creating a differential for.
		"-t7z"; # Use the 7z format.
		"-mx=7"; # Use a level 7 "high" compression.
		"-xr!thumbs.db"; # Exclude thumbs.db files wherever they are found.
		"-xr!*.log"; # Exclude all *.log files as well.
		#"-xr-@`"`"$excludesFile`"`"";
		#"-ir-@`"`"$includesFile`"`"";
		"-u-"; # Don't update the original archive (the full backup).
		"-up0q3r2x2y2z0w2!`"$OutputFile`""; # Flags to specify how the archive should be updated and the output file path (a *.7z file).;
		"$InputPath"
	)
	
	& $7zip @7zArgs | Tee-Object -LiteralPath "$OutputFile.log"
	if ($LASTEXITCODE -gt 1) # Ignores warnings which use exit code 1.
	{
		throw "7zip failed with exit code $LASTEXITCODE"
	}
}

function Backup-Run
{
	foreach($Directory in $DirectoriesToBackup)
	{
		$NewBackup = $null

		if(Test-Path $Directory)
		{
			$Date = Get-Date -UFormat "%Y%m%d"
			$Time = Get-Date -Format "HHmm"
			$DateTime = "$Date-$Time"
			$Base = (Split-Path $Directory -LeafBase).ToLower()

			if (-not (Test-Path "$OutputDirectory\$Base"))
			{
				New-Item "$OutputDirectory\$Base" -ItemType 'directory'
			}

			$fullBackup = Get-ChildItem -File -Path "$OutputDirectory\$Base\$Base-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z" | 
				Sort-Object FullName |
				Select-Object -Last 1 -ExpandProperty FullName

			if ($fullBackup -and (Test-Path $fullBackup))
			{
				$DateTime = $(Split-Path $fullBackup -LeafBase).Replace("$Base-", '')
				$differentialCount =  (Get-ChildItem -File -Path "$OutputDirectory\$Base\$Base-$DateTime-diff-*.7z").Count
				if ($differentialCount -ge $NumberOfDifferentials )
				{
					$NewBackup = $true
				}
				else {
					$NewBackup = $false
				}
			} else {
				$NewBackup = $true	
			}

			if ($NewBackup)
			{
				if (-not (Test-Path "$OutputDirectory\$Base\$Base-$Date-$Time.7z"))
				{
					Backup-Full -InputPath $Directory -OutputFile "$OutputDirectory\$Base\$Base-$Date-$Time.7z"
				}
			} else {
				if (-not (Test-Path "$OutputDirectory\$Base\$Base-$DateTime-diff-$Date-$Time.7z"))
				{
					Backup-Diff -InputPath $Directory -FullBackupPath $fullBackup -OutputFile "$OutputDirectory\$Base\$Base-$DateTime-diff-$Date-$Time.7z"
				}
			}

			while ((Get-ChildItem -File -Path "$OutputDirectory\$Base\$Base-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z").Count -gt $NumberOfFulls)
			{
				$backup = Get-ChildItem -File -Path "$OutputDirectory\$Base\$Base-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].7z" | 
					Sort-Object FullName -Descending|
					Select-Object -Last 1 -ExpandProperty FullName
				$DateTime = $(Split-Path $backup -LeafBase).Replace("$Base-", '')
				Remove-Item "$OutputDirectory\$Base\$Base-$DateTime*.*"
			}
		}
	}
}