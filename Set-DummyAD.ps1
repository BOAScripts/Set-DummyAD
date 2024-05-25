# static VARIABLES definition
$modelPath = ".\model.json"
$usersCSVPath = ".\1000names.csv"


# [1] Check local files presence and import in context
if ((Test-Path $modelPath) -or (Test-Path $usersCSVPath)){
    $model = Get-Content $modelPath | ConvertFrom-Json
    $CSVNames = [System.Collections.ArrayList](Get-Content $usersCSVPath | ConvertFrom-Csv -Delimiter ";")
}
else {
    Write-Host "$modelPath or $usersCSVPath not present!" -ForegroundColor Red
    Exit
}

# [2] Check/Install ADDS role
if ((Get-WindowsFeature AD-Domain-Services).Installed){
    Write-Host "-------------------------"
    Write-Host '[v] ADDS already installed' -ForegroundColor Green
    # Get domain.tld + domain DN
    try { 
        $domain = (Get-ADDomain).Forest
        $domainDN = (Get-ADRootDSE).rootDomainNamingContext
        Write-Host "    [i] $domain " -ForegroundColor Blue
        Write-Host "    [i] $domainDN" -ForegroundColor Blue
        Write-Host "-------------------------"
    }
    catch{
        write-host $_ -ForegroundColor Red
        write-host '[!] ADDS installed but no domain detected - is the server in a "WAITING TO PROMOTE" state ?' -ForegroundColor Red
        write-host '[!] Promote to DC and re-exectute this script' -ForegroundColor Red
    }
}
else {
    Write-Host "-------------------------"
    Write-Host '[!] ADDS not installed' -ForegroundColor Yellow
    $rep = Read-Host "    [?] Do you want to install Active Directory Domain and Services ? (y/n)"
    if ($rep -like 'y*'){
        Write-Host "    [!] DSRM password will be: $($model.PSW)" -ForegroundColor Yellow
        $DSRMpsw = ConvertTo-SecureString $model.PSW -AsPlainText -Force
        $domain = Read-Host "    [?] Please enter domain name (domain.tld)"
        try{
            Write-Host '[+] Trying to install ADDS role' -ForegroundColor Yellow
            Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
            Write-Host '[+] Trying to promote server as Domain Controller (expect a reboot warning)' -ForegroundColor Yellow
            Write-Host '[i] EXCPECT A REBOOT WARNING ONCE DONE' -ForegroundColor Yellow
            Install-ADDSForest -DomainName $domain -InstallDns -SafeModeAdministratorPassword $DSRMpsw -Force
            Write-Host '[!] You will be disconnected to login again with the domain Administrator (same password as local Adminstrator)' -ForegroundColor Yellow
            Write-Host "-------------------------"
        }
        catch{write-host $_ -ForegroundColor Red}
    }
    else {
        Write-Host "[!] You don't want to install ADDS - Exiting" -ForegroundColor Red
        Exit
    }
}

# [3] Populate AD
Write-Host "[i] Base AD generation" -ForegroundColor Green
## Create OUs
Write-Host "    [i] OUs generation" -ForegroundColor Blue
try {
    ### Root OU
    New-ADOrganizationalUnit -Name $model.RootOUName -Path $domainDN -ProtectedFromAccidentalDeletion $model.PreventOUDeletion
    $RootOUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $model.RootOUName).DistinguishedName
    Write-Host "        [+] $RootOUdn" -ForegroundColor Yellow
    ### Custom OUs in model.json
    foreach ($ouName in $model.CustomOUs) {
        if ($ouName -notlike "*/*"){
            # This a TOP OU
            New-ADOrganizationalUnit -Name $ouName -Path $RootOUdn -ProtectedFromAccidentalDeletion $model.PreventOUDeletion
        }
        else {
            # This is a SUB OU
            $parentOU, $childOU = $ouName.Split('/')[0], $ouName.Split('/')[1]
            $parentOUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $parentOU).DistinguishedName
            New-ADOrganizationalUnit -Name $childOU -Path $parentOUdn -ProtectedFromAccidentalDeletion $model.PreventOUDeletion   
        }
    }
    Write-Host "        [+] CustomOUs" -ForegroundColor Yellow
    Write-Host "    ---------------------"
    
    ### Prepare Departments generation
    $Depts = ($model.Depts).PSObject.Properties
    $OUusers = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq "Users").DistinguishedName
    $GGSOU = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq "GGS").DistinguishedName
    $DLGSOU = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq "DLGS").DistinguishedName
    if (!(Test-Path $model.RootShareName)){
        New-Item -Name $model.RootShareName -ItemType Directory -Path "C:\" | Out-Null
        # Convert NTFS to explicit instead of inherited
        icacls $model.RootSharePath /inheritance:d | Out-Null
        # Remove Users permissions
        $fACLs = Get-Acl $model.RootSharePath  
        foreach ($rule in $fACLs.Access){
            if ($rule.IdentityReference -like "*Users"){
                $fACLs.RemoveAccessRule($rule) | Out-Null
                    }
        }
        Set-Acl $model.RootSharePath  $fACLs | Out-Null
        Write-Host "[+] $($model.RootSharePath) - ONLY Admin access" -ForegroundColor Green
        Write-Host "-------------------------"
    }
    Write-Host "[i] Departments generation" -ForegroundColor Green
    ### foreach Depts in model.json
    foreach ($dept in $Depts){
        # Create Dept OU
        Write-Host "    [i] $($dept.Name)" -ForegroundColor Blue
        New-ADOrganizationalUnit -Name $dept.Name -Path $OUusers -ProtectedFromAccidentalDeletion $model.PreventOUDeletion
        Write-Host "        [+] $($dept.Name) OU" -ForegroundColor Yellow
        ### Set GGS groups
        ### 3 GGS / Department (ALL,Managers,Users)
        New-ADGroup -Name "GGS_$($dept.Value)_ALL" -GroupCategory Security -GroupScope Global -Path $GGSOU
        New-ADGroup -Name "GGS_$($dept.Value)_Managers" -GroupCategory Security -GroupScope Global -Path $GGSOU
        New-ADGroup -Name "GGS_$($dept.Value)_Users" -GroupCategory Security -GroupScope Global -Path $GGSOU
        ### Set DLGS groups
        ### 2 DLGS / Departement (Share_RO, Share_RW)
        New-ADGroup -Name "DLGS_$($dept.Value)_Share_RO" -GroupCategory Security -GroupScope DomainLocal -Path $DLGSOU
        New-ADGroup -Name "DLGS_$($dept.Value)_Share_RW" -GroupCategory Security -GroupScope DomainLocal -Path $DLGSOU
        Write-Host "        [+] $($dept.Name) Security groups (DLGS, GGS)" -ForegroundColor Yellow
        ### Assign DLGS to GGS
        Add-ADGroupMember -Identity "DLGS_$($dept.Value)_Share_RW" -Members "GGS_$($dept.Value)_Managers"
        Add-ADGroupMember -Identity "DLGS_$($dept.Value)_Share_RO" -Members "GGS_$($dept.Value)_Users"
        ### Create SharedFolder
        $DeptSharePath = "$($model.RootSharePath)\$($dept.Name)"
        if (!(Test-Path $DeptSharePath)){          
            New-Item -Name $dept.Name -ItemType Directory -Path $model.RootSharePath | Out-Null
            ### Set SMB: Everyone FC
            New-SmbShare -Name $dept.value -Path $DeptSharePath | Out-Null
            Grant-SmbShareAccess -Name $dept.value -AccountName 'Everyone' -AccessRight Full -Force | Out-Null
            ### Set NTFS: DLGS (RW, RO)
            $dirACL = Get-Acl $DeptSharePath
            $acrw = new-object System.Security.AccessControl.FileSystemAccessRule "DLGS_$($dept.Value)_Share_RW","Modify","ContainerInherit,ObjectInherit","None","Allow"
            $acro = new-object System.Security.AccessControl.FileSystemAccessRule "DLGS_$($dept.Value)_Share_RO","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow"
            $dirACL.AddAccessRule($acrw)
            $dirACL.AddAccessRule($acro)
            Set-Acl -Path $DeptSharePath -AclObject $dirACL
            # it does weird shit when not waiting the completion of the share
            Start-Sleep -Milliseconds 100
            Write-Host "        [+] $($dept.Name) Share directory - SMB & NTFS rights" -ForegroundColor Yellow
        }
        else {
            Write-Host "        [!] $($dept.Name) directory already exists - skipping SMB/NTFS" -ForegroundColor Red
        }
        
        Write-Host "    ---------------------"
    }
}
catch {Write-Host $_ -ForegroundColor Red}



## Get

