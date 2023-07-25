# Import the Exchange Online module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Connect-ExchangeOnline

# Specify the path to the input CSV file
$csvPath = "C:\TEMP\MESecGroupToCloud.csv"

# Specify the path to the output CSV file
$outputPath = "C:\TEMP\SecGroupOutputChanges.csv"

# Read the input CSV file
$groups = Import-Csv $csvPath

# Create an array to store the results
$results = @()

# Iterate through each group in the CSV
foreach ($group in $groups) {
    # Extract the group properties from the CSV
    $displayName = $group.displayName
    $primarySMTP = $group.mail
    $members = $group.Members -split ";"
    $owner = $group.ManagedBy
    $description = $group.Description
    $hideFromAddressLists = $group.msExchHideFromAddressLists
    $nickname = $group.mailNickname
    $proxyAddresses = $group.proxyAddresses -split ";"

    # Create the mail-enabled security group
    $newGroup = New-DistributionGroup -DisplayName $displayName -PrimarySmtpAddress $primarySMTP -ManagedBy $owner -Alias $nickname -Description $description -Force

    # Set the hide from address lists property if required
    if ($hideFromAddressLists -eq "TRUE") {
        Set-DistributionGroup $newGroup.Identity -HiddenFromAddressListsEnabled $true
    }

    # Add the group's email aliases
    if ($proxyAddresses) {
        foreach ($address in $proxyAddresses) {
            $newGroup | Add-DistributionGroupMember -Member $address -BypassSecurityGroupManagerCheck -Confirm:$false
        }
    }

    # Set the group type to mail-enabled security group
    $newGroup | Set-DistributionGroup -Type "MailUniversalSecurityGroup"

    # Add members to the group
    if ($members) {
        foreach ($member in $members) {
            Add-DistributionGroupMember -Identity $newGroup.Identity -Member $member
        }
    }

    # Add the group to the results array
    $results += $newGroup
}

# Export the results to the output CSV file
$results | Export-Csv -Path $outputPath -NoTypeInformation
