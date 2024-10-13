# Power Platform Dataverse 4 Teams Scripts

This repository contains PowerShell scripts for exporting, unpacking, importing, and publishing Power Platform solutions.

## Scripts

### Download From Source

This script exports a solution from the Power Platform environment and unpacks it.

#### Parameters
- `-solutionName`: The name of the solution to export.
- `-exportDirectory`: The directory where the solution will be exported.
- `-unpackDirectory`: The directory where the solution will be unpacked.

#### Usage
```powershell
.\pipelineScripts\downloadFromSource.ps1 -solutionName "YourSolutionName" -exportDirectory "YourExportDirectory" -unpackDirectory "YourUnpackDirectory"
```

### Release To Target

This script imports a solution into the Power Platform environment and publishes all customizations.

#### Parameters
- `-solutionFilePath`: The path to the solution file to import.
- `-environmentName`: The name of the target environment.

#### Usage
```powershell
.\pipelineScripts\releaseToTarget.ps1 -solutionFilePath "path\to\your\solution.zip" -environmentName "YourEnvironmentName"
```

## Diagram
```mermaid
graph LR
    A[Start] --> B[Export Solution]
    B --> C[Unpack Solution]
    C --> D[Import Solution]
    D --> E[Publish Customizations]
    E --> F[End]
```

## Adding as a Submodule

To add this repository as a submodule to another repository:

1. Navigate to the root directory of your target repository.
2. Run the following command to add the submodule:
    `git submodule add https://github.com/itweedie/PowerPaltform-Dataverse4Teams.git scripts/dataverse4Teams`
3. Initialize and update the submodule:
    `git submodule update --init --recursive`

## Running the Scripts as a Submodule

Once the repository is added as a submodule, you can run the scripts from the submodule location.

### Download From Source
```powershell
.\.scripts\dataverse4Teams\pipelineScripts\downloadFromSource.ps1 -solutionName "YourSolutionName" -exportDirectory "YourExportDirectory" -unpackDirectory "YourUnpackDirectory"
```

### Release To Target
```powershell
.\.scripts\dataverse4Teams\pipelineScripts\releaseToTarget.ps1 -solutionFilePath "path\to\your\solution.zip" -environmentName "YourEnvironmentName"
```

## Notes

- Ensure you have the required permissions and are authenticated with the correct environment before running the scripts.
- Update the paths and parameters according to your specific use case and environment setup.
