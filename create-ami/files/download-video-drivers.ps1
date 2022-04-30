$Bucket = "nvidia-gaming"
$LocalTemp = "C:\Users\Administrator\Desktop\temp"
$InstallationFiles = "C:\Users\Administrator\Desktop\InstallationFiles"

$Objects = Get-S3Object -BucketName $Bucket -KeyPrefix "windows/latest" -Region us-east-1
foreach ($Object in $Objects) {
    $LocalFileName = $Object.Key
    if ($LocalFileName -ne '' -and $Object.Size -ne 0) {
        $LocalFilePath = Join-Path $LocalTemp $LocalFileName
        Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region us-east-1
    }
}
Expand-Archive $LocalFilePath -DestinationPath $InstallationFiles\1_NVIDIA_drivers

