param (
    [string]$solutionName,
    [string]$exportDirectory,
    [string]$sourceEnv,
    [string]$unpackDirectory
)

# Inform the user that the script is starting
Write-Host "Starting the solution export and unpack process for solution: $solutionName"

# Connect to the source environment using device code authentication
Write-Host "Connecting to the environment: $sourceEnv"
try {
    pac auth create --environment $sourceEnv --deviceCode
    Write-Host "Successfully connected to the environment."
}
catch {
    Write-Host "ERROR: Failed to connect to the environment. Please check the environment ID and try again." -ForegroundColor Red
    return
}

# Export the solution
Write-Host "Exporting the solution: $solutionName to $exportDirectory"
try {
    pac solution export --name $solutionName --path $exportDirectory --overwrite --environment $sourceEnv
    Write-Host "Unmanaged solution export completed successfully."
        pac solution export --name $solutionName --path $exportDirectory --overwrite --environment $sourceEnv --managed
    Write-Host "Managed solution export completed successfully."
}
catch {
    Write-Host "ERROR: Solution export failed. Please ensure the solution name is correct and the solution exists in the environment." -ForegroundColor Red
    return
}

# Generate Solution Settings Template
Write-Host "Generating solution settings template for solution: $solutionName"
$settingsFilePath = "$unpackDirectory-SolutionSettings\TemplateSettingsFile.json"
try {
    pac solution create-settings --solution-zip "$exportDirectory\$solutionName.zip" --settings-file $settingsFilePath
    Write-Host "Solution settings template created at: $settingsFilePath"
}
catch {
    Write-Host "ERROR: Failed to generate solution settings template. Check that the solution zip file was exported correctly." -ForegroundColor Red
    Write-Host "Please verify that the solution zip file exists in $exportDirectory." -ForegroundColor Yellow
    return
}

# Unpack the solution
Write-Host "Unpacking the solution: $solutionName"
try {
    pac solution unpack --zipFile "$exportDirectory\$solutionName.zip" --folder $unpackDirectory --packagetype Both
    Write-Host "Solution unpacked successfully into folder: $unpackDirectory"
}
catch {
    Write-Host "ERROR: Failed to unpack the solution. Please ensure the solution zip file exists and is accessible." -ForegroundColor Red
    Write-Host "Check that $exportDirectory\$solutionName.zip is present and not corrupted." -ForegroundColor Yellow
    return
}

# Define the directory for CanvasApps
$canvasAppsToUnpack = "$unpackDirectory\CanvasApps"
Write-Host "Looking for Canvas Apps in: $canvasAppsToUnpack"

# Get all .msapp files in the CanvasApps folder
try {
    $msappFiles = Get-ChildItem -Path $canvasAppsToUnpack -Filter "*.msapp"
    if ($msappFiles.Count -eq 0) {
        Write-Host "No .msapp files found in $canvasAppsToUnpack"
    } else {
        Write-Host "Found $($msappFiles.Count) Canvas App(s) to unpack."
    }
}
catch {
    Write-Host "ERROR: Could not find the Canvas Apps folder at $canvasAppsToUnpack. Ensure the solution was unpacked correctly and contains Canvas Apps." -ForegroundColor Red
    return
}

# Loop through each .msapp file and unpack it
foreach ($msappFile in $msappFiles) {
    # Define the source directory for unpacking the Canvas App
    $sourceDirectory = Join-Path -Path "$unpackDirectory-UnpackedCanvasApp" -ChildPath $msappFile.BaseName
    Write-Host "Unpacking Canvas App: $($msappFile.Name) into $sourceDirectory"

    try {
        # Unpack the .msapp file and capture any output
        $output = pac canvas unpack --sources $sourceDirectory --msapp $msappFile.FullName *>&1

        # Check if the folder was created
        if (-not (Test-Path -Path $sourceDirectory)) {
            # If the folder doesn't exist, create it
            Write-Host "Creating directory: $sourceDirectory"
            New-Item -ItemType Directory -Force -Path $sourceDirectory

            # Write any output to an error log file
            $errorFilePath = Join-Path -Path $sourceDirectory -ChildPath "error.txt"
            Write-Host "Writing command output to $errorFilePath"
            $output | Out-File -FilePath $errorFilePath
        }

        Write-Host "Canvas App unpacked successfully: $($msappFile.Name)"
    }
    catch {
        # Handle any errors that occur during unpacking
        Write-Host "ERROR: Failed to unpack Canvas App: $($msappFile.Name). Writing error details to $sourceDirectory." -ForegroundColor Red

        # Ensure the directory exists
        if (-not (Test-Path -Path $sourceDirectory)) {
            New-Item -ItemType Directory -Force -Path $sourceDirectory
        }

        # Write the error to a text file
        $errorFilePath = Join-Path -Path $sourceDirectory -ChildPath "error.txt"
        $_ | Out-File -FilePath $errorFilePath
        Write-Host "Error details written to: $errorFilePath"
    }
}

# Inform the user that the process is complete
Write-Host "All operations completed successfully."
