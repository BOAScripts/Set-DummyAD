# [1] Check local files presence

$modelPath = ".\model.json"
$usersCSVPath = ".\1000names.csv"

if (!(Test-Path $modelPath)){
    Write-Host "$modelPath not present!" -ForegroundColor Red
    Exit
}
else {
    # IMPORT JSON in context
}
if (!(Test-Path $usersCSVPath)){
    Write-Host "$usersCSVPath not present!" -ForegroundColor Red
    Exit
}
else {
    # IMPORT CSV in context
}

# [2] Check/Install ADDS role
if ((Get-WindowsFeature AD-Domain-Services).Installed){
    Write-Host "[OK] ADDS already installed" -ForegroundColor Green
    # Get domain.tld + domain DN
    try { 
        $domain = (Get-ADDomain).Forest
        $domainDN = (Get-ADRootDSE).rootDomainNamingContext
    }
    catch{
        write-host $_ -ForegroundColor Red
        write-host "ADDS installed but no domain detected - is the server in a 'WAITING TO PROMOTE' state ?"
    }
}
else {
    Write-Host "[?] ADDS not installed" -ForegroundColor Yellow
    $rep = Read-Host " [?] Do you want to install Active Directory Domain and Services ? (y/n)"
    if ($rep -like 'y*'){
        # !!!!! GET PSW FROM MODEL !!!!!
        $DSRMpsw = ConvertTo-SecureString "Test1234=" -AsPlainText -Force
        $domain = Read-Host "Please enter domain name (domain.tld)"
        Write-Host "[+] Trying to install ADDS role" -ForegroundColor Yellow
        try{
            Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
        }
        catch{write-host $_ -ForegroundColor Red}
        Write-Host "[+] Trying to promote server as Domain Controller" -ForegroundColor Yellow 
        try{
            Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRMpsw        
        }
        catch{write-host $_ -ForegroundColor Red}
    }
    else {
        Write-Host "[?] You don't want to install ADDS - Exiting" -ForegroundColor Yellow
        Exit
    }
}

# [3] ZHU-LI, do the thing

# [3.1] Get Depts

# [3.1.1] Set SharedFolder % Depts

# [3.1.2] Set DLGS groups

# [3.1.3] Set GGS groups + membership of correspoding DLGS

