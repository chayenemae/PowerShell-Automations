# Import the Active Directory module
Import-Module ActiveDirectory

# Read the CSV file
$csvPath = "C:\TEMP\MESecGroupToCloud.csv"
$groups = Import-Csv $csvPath

# Create an array to store the results
$results = @()

# Iterate through each group in the CSV file
foreach ($group in $groups) {
    $groupEmail = $group.primarySMTP

    # Retrieve the security group
    $adGroup = Get-ADGroup -Filter {mail -eq $groupEmail} -Properties Description, ManagedBy, mail

    # Check if the group exists
    if ($adGroup) {
        # Retrieve the members of the security group
        $groupMembers = Get-ADGroupMember -Identity $adGroup.DistinguishedName

        # Retrieve member email addresses
        $memberEmails = $groupMembers | foreach {
            $memberEmail = ""
            if ($_.objectClass -eq "user") {
                $memberObj = Get-ADUser -Identity $_ -Properties EmailAddress
                $memberEmail = $memberObj.EmailAddress
            } elseif ($_.objectClass -eq "group") {
                $memberObj = Get-ADGroup -Identity $_ -Properties mail
                $memberEmail = $memberObj.mail
            }
            $memberEmail
        }

        # Create a custom object with the group details and joined member emails
        $groupDetails = [PSCustomObject]@{
            GroupEmail = $adGroup.mail
            MemberEmails = $memberEmails -join ";"
            GroupDescription = $adGroup.Description
            ManagedBy = $adGroup.ManagedBy
        }

        # Add the group details to the results array
        $results += $groupDetails
    } else {
        Write-Host "Security group with email $groupEmail not found."
    }
}


# Save the results to a CSV file
$outputPath = "C:\TEMP\MembersSecGroupsOutput.csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation