Param(
    [Parameter(Mandatory=$true)][string]$devstackIP
)

$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
$logDest = "\\$devstackIP\openstack\logs\$hostname"


Copy-Item -Recurse C:\OpenStack\Log\* $logDest
& "$scriptLocation\export-eventlog.ps1"
cp -Recurse -Container  C:\OpenStack\Logs\Eventlog\* $logDest

systeminfo >> $logDest\systeminfo.log
wmic qfe list >> $logDest\windows_hotfixes.log
pip freeze >> $logDest\pip_freeze.log
ipconfig /all >> $logDest\ipconfig.log

get-netadapter | Select-object * >> $logDest\get_netadapter.log
get-vmswitch | Select-object * >> $logDest\get_vmswitch.log
get-WmiObject win32_logicaldisk | Select-object * >> $logDest\disk_free.log
get-netfirewallprofile | Select-Object * >> $logDest\firewall.log
get-process | Select-Object * >> $logDest\get_process.log
get-service | Select-Object * >> $logDest\get_service.log

cmd /c sc qc nova-compute >> $logDest\nova_compute_service.log
cmd /c sc qc neutron-hyperv-agent >> $logDest\neutron_hyperv_agent_service.log
