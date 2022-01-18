if (!(Test-Path Z:)) {
    Initialize-Disk 1
    New-Partition -DiskNumber 1 -DriveLetter Z -UseMaximumSize
    Format-Volume -DriveLetter Z -FileSystem NTFS
    md Z:\SteamLibrary\steamapps\common
}