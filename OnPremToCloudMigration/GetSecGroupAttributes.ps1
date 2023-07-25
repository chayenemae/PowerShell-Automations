# Import the Active Directory module
Import-Module ActiveDirectory

# Read the CSV file
$csvPath = "C:\TEMP\MESecGroupToCloud.csv"
$groups = Import-Csv $csvPath

# Create an array to store the results
$results = @()

# Iterate through each group in the CSV file
foreach ($group in $groups) {
    $groupEmail = $group.mail

    # Retrieve the security group
    $adGroup = Get-ADGroup -Filter {mail -eq $groupEmail} -Properties msExchRequireAuthToSendTo, msExchHideFromAddressLists, proxyAddresses, mailNickname, groupType

    # Check if the group exists
    if ($adGroup) {
        # Process proxyAddresses attribute
        $proxyAddresses = $adGroup.proxyAddresses | Where-Object { $_ -notlike "x400:*" -and $_ -notlike "MS:SPSC*" } | ForEach-Object { $_.Trim() }
        $proxyAddresses = $proxyAddresses -join ";"

        # Create a custom object with the group details
        $groupDetails = [PSCustomObject]@{
            GroupEmail = $adGroup.mail
            msExchRequireAuthToSendTo = $adGroup.msExchRequireAuthToSendTo
            msExchHideFromAddressLists = $adGroup.msExchHideFromAddressLists
            proxyAddresses = $proxyAddresses
            mailNickname = $adGroup.mailNickname
            groupType = $adGroup.groupType
        }

        # Add the group details to the results array
        $results += $groupDetails
    } else {
        Write-Host "Security group with email $groupEmail not found."
    }
}

# Save the results to a CSV file
$outputPath = "C:\TEMP\SecGroupAttributes.csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation
