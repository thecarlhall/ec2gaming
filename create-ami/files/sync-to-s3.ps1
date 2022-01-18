echo "Getting creds..."
$AccountID = (Get-STSCallerIdentity).Account
$Bucket = "ec2gaming-${AccountID}"

echo "Synching docs..."
aws s3 sync 'C:\Users\Administrator\Documents\My Games' "s3://${Bucket}/My Games" `
    --storage-class INTELLIGENT_TIERING

echo "Synching games..."
aws s3 sync Z:\SteamLibrary "s3://${Bucket}/" `
    --exclude '*/*' `
    --include 'steamapps/appmanifest_*' `
    --include 'steamapps/common/*' `
    --storage-class INTELLIGENT_TIERING