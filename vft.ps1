import-module DataONTAP

$ntapuser = "root"
$ntappw = "N3wW0rld!!"
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

if (($args.Length % 2) -ne 0) {
    Write-Output "Need controller arguments asshole!"
    Exit 0
} else {
    $controllers = $args
}

for ($i = 0; $i -le $controllers.length-1; $i++) {
    $cont = Connect-NaController $controllers[$i] -Credential $cred -https
    if ( !(Get-NaLicense -Controller $cont -Names multistore).Licensed ) {
        Write-Output ""
        Write-Output "******************************************************************"
        Write-Output ("Controller: " + $cont.Name)
        Write-Output ("This controller is not licensed for Multistore. Skipping checks.")
        Write-Output "******************************************************************"
        Write-Output ""
    } else {
        $vfilers = Get-NaVfiler | ? {$_.Name -notmatch "vfiler0"}
        if ($vfilers -ne $null) {
            foreach ($vfiler in $vfilers) {
                if ( (get-navfilerprotocol $vfiler -Controller $cont).allowedprotocols -match "nfs") {
                    Write-Output "**********************************************************************************************************"
                    Write-Output "Checking vfiler $vfiler on controller $($cont.Name) for NFS export mismatches"
                    Write-Output "**********************************************************************************************************"
                    $vfstores = $vfiler.vfstores
                    foreach ($vfs in $vfstores) {
                        if ($vfs.isetc) {
                            Write-Output "Contents of /etc/exports file"
                            $command = "rdfile " + $vfs.path + "/etc/exports"
                            $exports = invoke-nassh -Controller $cont -Credential $cred -Command $command
                            $exports = (($exports -split "`n") | ? {$_ -match '^/vol/'} | sort-object) -join "`n"
                            $exports
                        }
                    }
                    $vf = Connect-NaController $controllers[$i] -Vfiler $vfiler.Name -Credential $cred
                    $command = "vfiler run " + $vfiler + " exportfs"
                    $vf_running_exports = invoke-nassh -Controller $cont -Credential $cred -Command $command
                    $vf_running_exports = (($vf_running_exports -split "`n") | ? {$_ -match '^/vol/'} | sort-object) -join "`n"
                    Write-Output ""
                    Write-Output "Exports in the running config"
                    $vf_running_exports
                    if ($exports -eq $vf_running_exports) {
                        Write-Output ""
                        Write-Output "Controller: $($cont.Name) Vfiler: $($vfiler): /etc/exports file and the running config MATCH"
                        Write-Output ""
                    } else {
                        Write-Output ""
                        Write-Output "Controller: $($cont.Name) Vfiler: $($vfiler): /etc/exports file and the running config DO NOT MATCH"
                        Write-Output ""
                    }
                } else {
                    Write-Output ""
                    Write-Output "******************************************************************"
                    Write-Output ("Controller: " + $cont.Name)
                    Write-Output ("Vfiler: " + $vfiler.Name)
                    Write-Output ("This vfiler does not allow NFS. Skipping checks.")
                    Write-Output "******************************************************************"
                    Write-Output ""
                }
            }
        } else {
            Write-Output ""
            Write-Output "*********************************************************************************"
            Write-Output ("Controller: " + $cont.Name)
            Write-Output ("This controller does not have any vfilers (other than vfiler0). Skipping checks.")
            Write-Output "*********************************************************************************"
            Write-Output ""
        }
    }
}
