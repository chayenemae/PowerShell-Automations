# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the path of the input CSV file
$csvPath = "C:\TEMP\ADSyncedGroupsNOEmailAddress.csv"

# Read the input CSV file
$inputData = Import-Csv -Path $csvPath

# Create an array to store the output data
$outputData = @()

# Process each row in the input CSV
foreach ($row in $inputData) {
    # Get the distribution group email address from the CSV
    $groupEmail = $row.DLName

    # Get the distribution group object from Active Directory
    $group = Get-ADGroup -Filter "Name -eq '$groupEmail'" -Properties Members -ErrorAction SilentlyContinue

    if ($group) {
        # Create an array to store the member email addresses
        $memberEmails = @()

        # Process each member of the distribution group
        foreach ($member in $group.Members) {
            # Get the user or contact object from Active Directory
            $obj = Get-ADObject -Identity $member -Properties mail -ErrorAction SilentlyContinue

            # If the object exists and has an email address
            if ($obj -and $obj.mail) {
                # Add the member email address to the array
                $memberEmails += $obj.mail
            }
        }

        # Create a new object with the distribution group email address and member email addresses
        $outputRow = [PSCustomObject]@{
            DLName = $groupEmail
            Members = $memberEmails -join ";"
        }

        # Add the output row to the output data array
        $outputData += $outputRow
    }
    else {
        Write-Warning "Distribution group with email address '$groupEmail' not found in Active Directory."
    }
}

# Display the output data
$outputData | Format-Table -AutoSize

$outputData | Export-Csv -Path "C:\TEMP\MembersEmails.csv" -NoTypeInformation
