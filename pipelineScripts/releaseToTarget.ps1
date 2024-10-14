param (
    [string]$solutionName,
    [string]$unpackDirectory,
    [string]$environmentSettingsFile, # Path to the environment settings file
    [string]$targetEnvironment, # Path to the target environment
    [string]$exportDirectory,
    [switch]$Managed # Switch to indicate if the solution should be managed
)

# Inform the user that the script is starting
Write-Host "Starting the solution import and re-pack process for solution: $solutionName"

# Connect to the source environment using device code authentication
Write-Host "Connecting to the environment: $targetEnvironment"
try {
    pac auth create --environment $targetEnvironment --deviceCode
    Write-Host "Successfully connected to the environment."
}
catch {
    Write-Host "ERROR: Failed to connect to the environment. Please check the environment ID and try again." -ForegroundColor Red
    return
}

# Re-pack the solution
Write-Host "Repacking the solution..."
$zipFilePath = "$exportDirectory\$solutionName_repack.zip"
pac solution pack --folder $unpackDirectory --zipFile $zipFilePath
Write-Host "Solution repacked to: $zipFilePath"

# Determine if the solution should be imported as managed or unmanaged
if ($Managed) {
    Write-Host "Preparing to import as a managed solution..."
    $importType = "--convert-to-managed"
} else {
    Write-Host "Preparing to import as an unmanaged solution..."
    $importType = ""
}

# Push the solution to the target environment
Write-Host "Importing the solution to the target environment: $targetEnvironment"

# Check if the environmentSettingsFile is provided
if ([string]::IsNullOrWhiteSpace($environmentSettingsFile)) {
    # Run the import without the settings file
    Write-Host "No environment settings file provided, importing solution without settings file..."
    pac solution import --path $zipFilePath --environment $targetEnvironment --async $importType
} else {
    # Run the import with the settings file
    Write-Host "Using environment settings file: $environmentSettingsFile"
    pac solution import --path $zipFilePath --environment $targetEnvironment --settings-file $environmentSettingsFile --async $importType
}

Write-Host "Solution import process initiated."
