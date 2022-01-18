echo "Getting creds..."
$AccountID = (Get-STSCallerIdentity).Account
$Bucket = "ec2gaming-${AccountID}"

echo "Synching docs..."
aws s3 sync "s3://${Bucket}/My Games" 'C:\Users\Administrator\Documents\My Games'

echo "Synching manifests..."
aws s3 sync "s3://${Bucket}/" Z:\SteamLibrary `
    --exclude '*/*' `
    --include 'steamapps/appmanifest_*'

echo "Listing games..."
$Games = (aws s3 ls "s3://${Bucket}/steamapps/common/") -replace '^.*PRE ([^/]+).*$', "`$1"

# convert list to array
for ($i = 0; $i -lt $Games.count; $i++) {
    $Count = $i + 1
    "$Count " + $Games[$i]
}
[uint16]$GameID = Read-Host "Choose which title # to sync"

# reset index to 0-base
$GameID = $GameID - 1

$Title = $Games[$GameID]
if ( $Title -eq "" -or $Title -eq $null ) {
    echo "Try again using a number on the left of the title you want."
    exit 1
}

echo "Syncing '${Title}' to 'Z:\SteamLibrary\steamapps\common\${Title}'"
aws s3 sync "s3://${Bucket}/steamapps/common/${Title}" "Z:\SteamLibrary\steamapps\common\${Title}"