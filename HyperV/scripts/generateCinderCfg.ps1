Param(
    [Parameter(Mandatory=$true)][string]$configDir,
    [Parameter(Mandatory=$true)][string]$templatePath,
    [Parameter(Mandatory=$true)][string]$serverIP,
    [Parameter(Mandatory=$true)][string]$rabbitUser,
    [Parameter(Mandatory=$true)][string]$logDir,
    [Parameter(Mandatory=$true)][string]$lockPath
)

$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\utils.ps1"


$serverIP =  (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp).IPAddress
$volumeDriver = 'cinder.volume.drivers.windows.smbfs.WindowsSmbfsDriver'
$smbSharesConfigPath = "$configDir\smbfs_shares_config.txt"
$configFile = "$configDir\cinder.conf"


$sharePath = "//$serverIP/SMBShare"
sc $smbSharesConfigPath $sharePath

$template = gc $templatePath
$config = expand_template $template
Write-Host "Config file:"
Write-Host $config
sc $configFile $config

# Ensure Windows Share is available
if (! (Test-Path -Path C:\SMBShare))
{
    mkdir c:\SMBShare
}

if (!(Get-SMBShare -Name SMBShare))
{
    $hostname=hostname
    New-SMBShare -Name SMBShare -Path C:\SMBShare -FullAccess "$hostname\Administrator"
}

Grant-SmbShareAccess -Name SMBShare -AccountName Everyone -AccessRight Full -Force
# This will update the filesystem ACLs as well.
Set-SmbPathAcl -ShareName SMBShare
