# Import the Active Directory module
Import-Module ActiveDirectory

# Set the path to the CSV file
$csvFilePath = "C:\TEMP\RecreateADSyncedGroups.csv"

# Set the output CSV file path
$outputCsvFilePath = "C:\TEMP\NestedGroups.csv"

# Set the target OU
$targetOU = "OU=MySPS,OU=Departments,DC=spscommerce,DC=com"

# Read the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Create an empty array to store the results
$results = @()

# Loop through each row in the CSV file
foreach ($row in $csvData) {
    # Retrieve the distribution group display name from the "DLName" column
    $groupName = $row.DLName

    # Retrieve the distribution group
    $group = Get-ADGroup -Filter "DisplayName -eq '$groupName'"

    # Check if the group was found
    if ($group) {
        # Retrieve the members of the distribution group that do not belong to the target OU
        $nonTargetOUMembers = $group | Get-ADGroupMember |
            Where-Object { $_.DistinguishedName -notlike "*,$targetOU" }

        # If there are non-target-OU members, add the group to the results
        if ($nonTargetOUMembers) {
            # Create a custom object with the group name and add it to the results array
            $result = [PSCustomObject] @{
                GroupName = $groupName
            }
            $results += $result
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputCsvFilePath -NoTypeInformation

Write-Output "Output saved to '$outputCsvFilePath'."