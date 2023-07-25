# Import the Active Directory module
Import-Module ActiveDirectory

# Define the path to the CSV file
$csvPath = "C:\TEMP\OnPremMESecGroups.csv"

# Define the output CSV file path
$outputCsvPath = "C:\TEMP\MESGMembers.csv"

# Read the CSV file
$groups = Import-Csv -Path $csvPath

# Create an empty array to store the results
$results = @()

# Loop through each group in the CSV file
foreach ($group in $groups) {
    # Get the group name from the "Name" column
    $groupName = $group.Name

    # Retrieve the group object from Active Directory
    $groupObject = Get-ADGroup -Filter "Name -eq '$groupName'"

    if ($groupObject) {
        # Get the members of the group
        $groupMembers = Get-ADGroupMember -Identity $groupObject.DistinguishedName |
                        Where-Object { $_.objectClass -eq 'user' }

        if ($groupMembers) {
            # Retrieve the email addresses of the members and concatenate them
            $emailAddresses = $groupMembers | ForEach-Object {
                $userObject = Get-ADUser -Identity $_.DistinguishedName -Properties EmailAddress
                $userObject.EmailAddress
            } | Where-Object { $_ -ne $null }

            # Create an object to store the group name and concatenated email addresses
            $result = [PSCustomObject]@{
                GroupName = $groupObject.Name
                EmailAddresses = $emailAddresses -join ';'
            }

            # Add the result object to the results array
            $results += $result
        } else {
            # Group has no members
            Write-Host "Group Name: $($groupObject.Name)"
            Write-Host "This group has no members."
            Write-Host
        }
    } else {
        # Group not found in Active Directory
        Write-Host "Group Name: $groupName"
        Write-Host "Group not found in Active Directory."
        Write-Host
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputCsvPath -NoTypeInformation

# Display success message
Write-Host "Results exported to $outputCsvPath"