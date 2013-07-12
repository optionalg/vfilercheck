import-module DataONTAP

$ntapuser = "root"
$ntappw = "YOUR_ROOT_PASSWORD"
$pw = convertto-securestring $ntappw -asplaintext -force
$cred = new-object -typename system.management.automation.pscredential -argumentlist $ntapuser,$pw

$cont = Connect-NaController YOUR_CONTROLLER_NAME_OR_IP -Credential $cred -https

get-navol -controller $cont | foreach-object {
    $_.Name
    $volstr = "/vol/" + $_.Name
    # If you want to test what it would do before actually running reallocate jobs, use the -WhatIf paramter
    # Start-NaReallocate -Path $volstr -Controller $cont -RunOnce -WhatIf
    Start-NaReallocate -Path $volstr -Controller $cont -RunOnce 
}
