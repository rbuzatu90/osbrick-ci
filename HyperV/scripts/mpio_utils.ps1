function mpio_feature_enabled {
    $enabled = [bool]($(Get-WindowsFeature multipath-io).Installed)
    write-host "Windows MPIO feature enabled: $enabled"
    return $enabled
}

function 3par_mpio_enabled {
    $enabled = [bool]($(mpclaim -h | select-string "3PARDataVV"))
    write-host "MPIO service configured to claim 3par disks: $enabled"
    return $enabled
}

function mpio_configured {
    return ($(mpio_feature_enabled) -and $(3par_mpio_enabled))
}

function configure_mpio {
    # This requires a reboot, but it seems it's not mandatory
    # if no FC disks are already attached.
    if (! $(mpio_feature_enabled)) {
       write-host "Enabling MPIO Windows feature"
       install-windowsfeature multipath-io
    }
    if (! $(3par_mpio_enabled)) {
        write-host "Enabling MPIO support for 3PAR disks"
        mpclaim -n -i -d 3PARdataVV
    }
}
