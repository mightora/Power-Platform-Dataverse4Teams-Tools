param (
    [string]$solutionName,
    [string]$exportDirectory,
    [string]$unpackDirectory
)

# Get the current environment
Write-Host "You are currently connected to:"
pac auth list

# Ask for confirmation
$confirmation = Read-Host "IMPORTANT - Is your development environment listed and marked as active? (yes/no)"

if ($confirmation -ne 'yes') {
    Write-Host "Exiting script as the user is not connected to the correct environment. Please use pac auth help if you need help connecting to the correct environment. "
    exit
}

# Export the solution
pac solution export --name $solutionName --path $exportDirectory --overwrite

# Generate Solution Settings Template
pac solution create-settings --solution-zip "$exportDirectory\$solutionName.zip" --settings-file "$unpackDirectory-SolutionSettings\TemplateSettingsFile.json"

# Unpack the solution
pac solution unpack --zipFile "$exportDirectory\$solutionName.zip" --folder $unpackDirectory

# Directory to the CanvasApps folder
$canvasAppsToUnpack = "$unpackDirectory\CanvasApps"

# Get all .msapp files
$msappFiles = Get-ChildItem -Path $canvasAppsToUnpack -Filter "*.msapp"

# Loop through each .msapp file
foreach ($msappFile in $msappFiles) {
    # Define the source directory for unpacking
    $sourceDirectory = Join-Path -Path "$unpackDirectory-UnpackedCanvasApp" -ChildPath $msappFile.BaseName

    try {
        # Unpack the .msapp file and capture the output
        $output = pac canvas unpack --sources $sourceDirectory --msapp $msappFile.FullName *>&1

        # Check if the folder exists
        if (-not (Test-Path -Path $sourceDirectory)) {
            # Create the directory if it doesn't exist
            New-Item -ItemType Directory -Force -Path $sourceDirectory

            # Write the output of the pac command to a text file in the sources folder
            $errorFilePath = Join-Path -Path $sourceDirectory -ChildPath "error.txt"
            $output | Out-File -FilePath $errorFilePath
        }
    }
    catch {
        # Create the directory if it doesn't exist
        if (-not (Test-Path -Path $sourceDirectory)) {
            New-Item -ItemType Directory -Force -Path $sourceDirectory
        }

        # Write the error details to a text file in the sources folder
        $errorFilePath = Join-Path -Path $sourceDirectory -ChildPath "error.txt"
        $_ | Out-File -FilePath $errorFilePath
    }
}
