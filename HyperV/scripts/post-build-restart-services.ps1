# This script restart the nova and neutron services and cleans logs
# Needed to compensate for HyperV building ahead of time
#
Param(
    [string]$JOB_TYPE='iscsi'
)

. "C:\OpenStack\osbrick-ci\HyperV\scripts\config.ps1"
. "C:\OpenStack\osbrick-ci\HyperV\scripts\utils.ps1"

Write-Host "post-build: Starting the services!"

$currDate = (Get-Date).ToString()
Write-Host "$currDate Starting nova-compute service"
Try
{
    Start-Service nova-compute
}
Catch
{
    $proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\nova-compute.exe" -ArgumentList "--config-file $configDir\nova.conf"
    Start-Sleep -s 30
    if (! $proc.HasExited) {Stop-Process -Id $proc.Id -Force}
    Throw "Can not start the nova-compute service"
}
Start-Sleep -s 30
if ($(get-service nova-compute).Status -eq "Stopped")
{
    $currDate = (Get-Date).ToString()
    Write-Host "$currDate We try to start:"
    Write-Host Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\nova-compute.exe" -ArgumentList "--config-file $configDir\nova.conf"
    Try
    {
        $proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\nova-compute.exe" -ArgumentList "--config-file $configDir\nova.conf"
    }
    Catch
    {
        Throw "Could not start the process manually"
    }
    Start-Sleep -s 30
    if (! $proc.HasExited)
    {
        Stop-Process -Id $proc.Id -Force
        Throw "Process started fine when run manually."
    }
    else
    {
        Throw "Can not start the nova-compute service. The manual run failed as well."
    }
}

$currDate = (Get-Date).ToString()
Write-Host "$currDate Starting neutron-hyperv-agent service"
Try
{
    Start-Service neutron-hyperv-agent
}
Catch
{
    $proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\neutron-hyperv-agent.exe" -ArgumentList "--config-file $configDir\neutron_hyperv_agent.conf"
    Start-Sleep -s 30
    if (! $proc.HasExited) {Stop-Process -Id $proc.Id -Force}
    Throw "Can not start the neutron-hyperv-agent service"
}
Start-Sleep -s 30
if ($(get-service neutron-hyperv-agent).Status -eq "Stopped")
{
    $currDate = (Get-Date).ToString()
    Write-Host "$currDate We try to start:"
    Write-Host Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\neutron-hyperv-agent.exe" -ArgumentList "--config-file $configDir\neutron_hyperv_agent.conf"
    Try
    {
        $proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonDir\Scripts\neutron-hyperv-agent.exe" -ArgumentList "--config-file $configDir\neutron_hyperv_agent.conf"
    }
    Catch
    {
        Throw "Could not start the process manually"
    }
    Start-Sleep -s 30
    if (! $proc.HasExited)
    {
        Stop-Process -Id $proc.Id -Force
        Throw "Process started fine when run manually."
    }
    else
    {
        Throw "Can not start the neutron-hyperv-agent service. The manual run failed as well."
    }
}

if ($JOB_TYPE -eq "smbfs")
    {
    $currDate = (Get-Date).ToString()
    Write-Host "$currDate Starting cinder-volume service"
    Try
    {
        Start-Service cinder-volume
    }
    Catch
    {
        $proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonScripts\cinder-volume.exe" -ArgumentList "--config-file $configDir\cinder.conf"
        Start-Sleep -s 30
        if (! $proc.HasExited) {Stop-Process -Id $proc.Id -Force}
        Throw "Can not start the cinder-volume service"
    }
    Start-Sleep -s 30
    if ($(get-service cinder-volume).Status -eq "Stopped")
    {
        $currDate = (Get-Date).ToString()
        Write-Host "$currDate We try to start:"
        Write-Host Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonScripts\cinder-volume.exe" -ArgumentList "--config-file $configDir\cinder.conf"
        Try
        {
            $proc = Start-Process -PassThru -RedirectStandardError "$openstackLogs\process_error.txt" -RedirectStandardOutput "$openstackLogs\process_output.txt" -FilePath "$pythonScripts\cinder-volume.exe" -ArgumentList "--config-file $configDir\cinder.conf"
        }
        Catch
        {
            Throw "Could not start the process manually"
        }
        Start-Sleep -s 30
        if (! $proc.HasExited)
        {
            Stop-Process -Id $proc.Id -Force
            Throw "Process started fine when run manually."
        }
        else
        {
            Throw "Can not start the cinder-volume service. The manual run failed as well."
        }
    }
}
