$7zip = "$PSScriptRoot\7zip\7za.exe"

$DirectoriesToBackup = @(
	"C:\SourceFolder\"
)

$OutputDirectory = "C:\TargetFolder"

$NumberOfDifferentials = 13
$NumberOfFulls = 10