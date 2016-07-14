function ExecRetry($command, $maxRetryCount = 10, $retryInterval=2)
{
    $currErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $retryCount = 0
    while ($true)
    {
        try 
        {
            & $command
            break
        }
        catch [System.Exception]
        {
            $retryCount++
            if ($retryCount -ge $maxRetryCount)
            {
                $ErrorActionPreference = $currErrorActionPreference
                throw
            }
            else
            {
                Write-Error $_.Exception
                Start-Sleep $retryInterval
            }
        }
    }

    $ErrorActionPreference = $currErrorActionPreference
}

function GitClonePull($path, $url, $branch="master")
{
    Write-Host "Calling GitClonePull with path=$path, url=$url, branch=$branch"
    if (!(Test-Path -path $path))
    {
        ExecRetry {
            git clone $url $path
            if ($LastExitCode) { throw "git clone failed - GitClonePull - Path does not exist!" }
        }
        pushd $path
        git checkout $branch
        git pull
        popd
        if ($LastExitCode) { throw "git checkout failed - GitCLonePull - Path does not exist!" }
    }else{
        pushd $path
        try
        {
            ExecRetry {
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue "$path\*"
                git clone $url $path
                if ($LastExitCode) { throw "git clone failed - GitClonePull - After removing existing Path.." }
            }
            ExecRetry {
                (git checkout $branch) -Or (git checkout master)
                if ($LastExitCode) { throw "git checkout failed - GitClonePull - After removing existing Path.." }
            }

            Get-ChildItem . -Include *.pyc -Recurse | foreach ($_) {Remove-Item $_.fullname}

            git reset --hard
            if ($LastExitCode) { throw "git reset failed!" }

            git clean -f -d
            if ($LastExitCode) { throw "git clean failed!" }

            ExecRetry {
                git pull
                if ($LastExitCode) { throw "git pull failed!" }
            }
        }
        finally
        {
            popd
        }
    }
}


function dumpeventlog($path){
	
	Get-Eventlog -list | Where-Object { $_.Entries -ne '0' } | ForEach-Object {
		$logFileName = $_.LogDisplayName
		$exportFileName =$path + "\eventlog_" + $logFileName + ".evt"
		$exportFileName = $exportFileName.replace(" ","_")
		$logFile = Get-WmiObject Win32_NTEventlogFile | Where-Object {$_.logfilename -eq $logFileName}
		try{
			$logFile.backupeventlog($exportFileName)
		} catch {
			Write-Host "Could not dump $_.LogDisplayName (it might not exist)."
		}
	}
}

function exporteventlog($path){

	Get-Eventlog -list | Where-Object { $_.Entries -ne '0' } | ForEach-Object {
		$logfilename = "eventlog_" + $_.LogDisplayName + ".txt"
		$logfilename = $logfilename.replace(" ","_")
		Get-EventLog -Logname $_.LogDisplayName | fl | out-file $path\$logfilename -ErrorAction SilentlyContinue
	}
}

function exporthtmleventlog($path){
	$css = Get-Content $eventlogcsspath -Raw
	$js = Get-Content $eventlogjspath -Raw
	$HTMLHeader = @"
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script type="text/javascript">$js</script>
<style type="text/css">$css</style>
"@

	foreach ($i in (Get-EventLog -List | Where-Object { $_.Entries -ne '0' }).Log) {
		$Report = Get-EventLog $i
		$Report = $Report | ConvertTo-Html -Title "${i}" -Head $HTMLHeader -As Table
		$Report = $Report | ForEach-Object {$_ -replace "<body>", '<body id="body">'}
		$Report = $Report | ForEach-Object {$_ -replace "<table>", '<table class="sortable" id="table" cellspacing="0">'}
		$logName = "eventlog_" + $i + ".html"
		$logName = $logName.replace(" ","_")
		$bkup = Join-Path $path $logName
		$Report = $Report | Set-Content $bkup
	}
	#Also getting the hyper-v logs
	$rep = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Hyper-V*"}
	$rep = $rep | ConvertTo-Html -Title "Hyper-V" -Head $HTMLHeader -As Table
 	$rep = $rep | ForEach-Object {$_ -replace "<body>", '<body id="body">'}
	$rep = $rep | ForEach-Object {$_ -replace "<table>", '<table class="sortable" id="table" cellspacing="0">'}
	$logName = "eventlog_hyperv.html"
	$bkup = Join-Path $path $logName
	$rep = $rep | Set-Content $bkup
}

function cleareventlog(){
	Get-Eventlog -list | ForEach-Object {
		Clear-Eventlog $_.LogDisplayName -ErrorAction SilentlyContinue
	}
}

function cherry_pick($commit) {
    $eapSet = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git cherry-pick $commit

    if ($LastExitCode) {
        echo "Ignoring failed git cherry-pick $commit"
        git checkout --force
    }
    $ErrorActionPreference = $eapSet
}

function log_message($message){
    echo "[$(Get-Date)] $message"
}

function get_iscsi_targets() {
    return gwmi -ns root/microsoft/windows/storage -class msft_iscsitarget
}

function get_iscsi_portals() {
    return gwmi -ns root/microsoft/windows/storage -class msft_iscsitargetportal
}

function cleanup_iscsi_targets() {
    # TODO(lpetrut): this was useful when dynamic iSCSI targets where used,
    # while this function will be unable to remove static targets. Normally,
    # this should not be an issue, as right now, we shouldn't have leaking targets.
    #
    # Anyway, in order to ensure that all the iSCSI targets have been cleaned up,
    # we'll have to update this function, using iscsicli or even os-win, as WMI
    # does not expose what we need.

    #Checking the number of iSCSI targets and portals before clean-up
    $targets = get_iscsi_portals
    log_message "[PRE_CLEAN] $env:computername has iSCSI targets: $targets"

    $portals = get_iscsi_portals
    log_message "[PRE_CLEAN] $env:computername has iSCSI portals: $portals"

    log_message "Started cleaning iSCSI targets and portals"
    $ErrorActionPreference = "Continue"

    $targets[0].update()
    foreach ($portal in $portals) {$portal.remove()}

    log_message "Finished cleaning iSCSI targets and portals"

    #Checking the number of iSCSI targets and portals after clean-up
    $targets = get_iscsi_targets
    log_message "[POST_CLEAN] $env:computername has iSCSI targets: $targets"

    $portals = get_iscsi_portals
    log_message "[POST_CLEAN] $env:computername has iSCSI portals: $portals"
    # Restarting MSiSCSI service 
    restart-service msiscsi; iscsicli listtargets; iscsicli listtargetportals
}