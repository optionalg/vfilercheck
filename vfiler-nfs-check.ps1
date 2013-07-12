import-module DataONTAP

$ntapuser = "root"
$ntappw = "N3wW0rld!!"
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

if ($args.Length -eq 0) {
    Write-Output "Need controller arguments asshole!"
    Exit 0
} else {
    $controllers = $args
}

$intloc = Get-Location
for ($i = 0; $i -le $controllers.length-1; $i++) {
    $cont = Connect-NaController $controllers[$i] -Credential $cred
    $vfilers = Get-NaVfiler | Select Name | ? {$_.Name -notmatch "vfiler0"}
    foreach ($vfiler in $vfilers) {
        $vf = Connect-NaController $controllers[$i] -Vfiler $vfiler.Name -Credential $cred
        $psd = Mount-NaController -Controller $vf
        $path = $vfiler.Name + ":/etc"
        cd $path
        $exports = $path + "/exports"
        if (test-path $exports) {
            $vfexports = Get-Content exports | %{$data = [regex]::split($_, '\t'); Write-Output "$($data[0])" | where {$data[0] -match "/vol"}}
            $vf_running_exports = @()
            Get-NaNfsExport -Controller $vf | Foreach-Object {
                $vf_running_exports += $_.Pathname
            }
            ForEach ($element in $vf_running_exports) {
                if ($vfexports -contains $element) {
                    Continue
                } else {
                    Write-Output ""
                    Write-Output ("Controller: " + $cont.Name)
                    Write-Output ("Vfiler: " + $vfiler.Name)
                    Write-Output "Check $element"
                    Write-Output ("The running NFS config for the above vfiler does not match the etc/exports file!")
                    Write-Output ""
                }
            }
        } else {

            Write-Output ""
            Write-Output "******************************************************************"
            Write-Output ("Controller: " + $cont.Name)
            Write-Output ("Vfiler: " + $vfiler.Name)
            Write-Output ("This vfiler DOES NOT have an etc CIFS share.  Check it Manually!")
            Write-Output "******************************************************************"
            Write-Output ""
        }
    }
}
cd $intloc
