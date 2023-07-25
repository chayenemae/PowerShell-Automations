# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the path of the input CSV file
$csvPath = "C:\TEMP\OnPremMESecGroups.csv"

# Read the input CSV file
$inputData = Import-Csv -Path $csvPath

# Create an array to store the output data
$outputData = @()

# Process each row in the input CSV
foreach ($row in $inputData) {
    # Get the distribution group email address from the CSV
    $groupEmail = $row.Name

    # Check if the group email address is empty
    if (![string]::IsNullOrEmpty($groupEmail)) {
        # Get the distribution group object from Active Directory
        $group = Get-ADGroup -Filter "Name -eq '$groupEmail'" -Properties ManagedBy -ErrorAction SilentlyContinue

        if ($group) {
            # Check if the group has a managed by user
            if (![string]::IsNullOrEmpty($group.ManagedBy)) {
                # Get the managed by user object from Active Directory
                $managedBy = Get-ADUser -Identity $group.ManagedBy -Properties mail -ErrorAction SilentlyContinue

                if ($managedBy -and $managedBy.mail) {
                    # Create a new object with the distribution group email address and managed by email address
                    $outputRow = [PSCustomObject]@{
                        DLName = $groupEmail
                        ManagedBy = $managedBy.mail
                    }

                    # Add the output row to the output data array
                    $outputData += $outputRow
                }
                else {
                    Write-Warning "ManagedBy user not found or does not have an email address for distribution group '$groupEmail'."
                }
            }
            else {
                # Create a new object with the distribution group email address and an empty ManagedBy column
                $outputRow = [PSCustomObject]@{
                    DLName = $groupEmail
                    ManagedBy = ""
                }

                # Add the output row to the output data array
                $outputData += $outputRow
            }
        }
        else {
            Write-Warning "Distribution group with email address '$groupEmail' not found in Active Directory."
        }
    }
    else {
        Write-Warning "Empty email address found in the CSV file."
    }
}

# Display the output data
$outputData | Format-Table -AutoSize


$outputData | Export-Csv -Path "C:\TEMP\OwnersOnPremMESecGroups.csv" -NoTypeInformation
