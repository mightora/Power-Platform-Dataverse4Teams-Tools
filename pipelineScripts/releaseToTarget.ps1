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


# Run the command and parse the JSON output
$jsonOutput = pac solution list --json | ConvertFrom-Json

# Find the solution using the SolutionUniqueName
$solution = $jsonOutput | Where-Object { $_.SolutionUniqueName -eq $solutionName }

# Get the current version number
$currentVersion = $solution.VersionNumber

# Split the version number into its components (Major, Minor, Build, Revision)
$versionParts = $currentVersion -split "\."

# Convert each part to integers to ensure proper arithmetic operations
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$build = [int]$versionParts[2]
$revision = [int]$versionParts[3]

# Increment the Minor version by 1
$revision += 1

# Reconstruct the new version number
$newVersion = "$major.$minor.$build.$revision"


# update the version
pac solution version --revisionversion $revision --solutionPath $unpackDirectory

# Output the new version number
Write-Output "The new version number for solution '$solutionName' is $newVersion"


# Re-pack the solution name
Write-Host "Repacking the solution..."
$zipFilePath = Join-Path -Path $exportDirectory -ChildPath "repack\$solutionName.zip"

# Determine if the solution should be imported as managed or unmanaged
if ($Managed) {

    pac solution pack --folder $unpackDirectory --zipFile $zipFilePath --packagetype Managed
    Write-Host "Solution repacked to: $zipFilePath"

    Write-Host "Preparing to import as a managed solution..."
    $importType = "--convert-to-managed"

} else {
    
        pac solution pack --folder $unpackDirectory --zipFile $zipFilePath --packagetype Unmanaged
    Write-Host "Solution repacked to: $zipFilePath"

    Write-Host "Preparing to import as an unmanaged solution..."
    $importType = ""
}

# Push the solution to the target environment
Write-Host "Importing the solution to the target environment: $targetEnvironment"

# Check if the environmentSettingsFile is provided
if ([string]::IsNullOrWhiteSpace($environmentSettingsFile)) {
    # Run the import without the settings file
    Write-Host "No environment settings file provided, importing solution without settings file..."
    pac solution import --path $zipFilePath --environment $targetEnvironment --async $importType --publish-changes
} else {
    # Run the import with the settings file
    Write-Host "Using environment settings file: $environmentSettingsFile"
    pac solution import --path $zipFilePath --environment $targetEnvironment --settings-file $environmentSettingsFile --async $importType --publish-changes
}

Write-Host "Solution import process initiated."
