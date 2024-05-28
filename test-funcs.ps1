$modelPath = ".\model.json"
$model = Get-Content $modelPath | ConvertFrom-Json


<#
.SYNOPSIS
Create new OUs and subOUs

.DESCRIPTION
Create new OUs and subOUs from the .json input in the $ParentOU 

.PARAMETER ParentOU
Distinguished name of the parent OU where the OU and subOUs will be created

.PARAMETER model_in
Imported data from a .json with at least an "OUName" key value in it.

.PARAMETER Custom
Switch to use when there are more than one OU/subOUs in the $model_in, OU name key should match "CustomNameX" and subOUs array key should match "subOUsX" (where x begin at 1)

.PARAMETER Protected
boolean to set "ProtectedFromAccidentalDeletion" when creating the OU/subOUs

.EXAMPLE
New-OUsGeneration -ParentOU "OU=_ROOT,DC=testdom,DC=local" -model_in ($model.SecGroupsOUs)
New-OUsGeneration -ParentOU "OU=_ROOT,DC=testdom,DC=local" -model_in ($model.CustomOUs) -Custom
#>
function New-OUsGeneration{
    param (
        $ParentOU,
        $model_in,
        [bool]$Protected,
        [switch]$Custom
    )
    if (!$Custom){
        New-ADOrganizationalUnit -Name $model_in.OUName -Path $ParentOU -ProtectedFromAccidentalDeletion $Protected
        $OUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $model_in.OUName).DistinguishedName
        write-host "[+] $($model_in.OUName)" -ForegroundColor Yellow
        foreach ($subOU in $model_in.subOUS){
            New-ADOrganizationalUnit -Name $subOU -Path $OUdn -ProtectedFromAccidentalDeletion $Protected
            Write-Host "    [+] $subOU" -ForegroundColor Yellow
        }
    }
    else {
        # process looping throug each CustomNameX
        $index = 1
        while ($true) {
            $ouNameIter = "CustomName$index"
            $subOUsIter = "subOUs$index"

            if ($model_in.PSObject.Properties.Name -contains $ouNameIter) {
                $ouName = $model_in.$ouNameIter
                $subOUs = $model_in.$subOUsIter
                New-ADOrganizationalUnit -Name $ouName -Path $ParentOU -ProtectedFromAccidentalDeletion $Protected
                $OUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $ouName).DistinguishedName
                Write-Host "[+] $ouName"
                foreach ($subOU in $subOUs) {
                    New-ADOrganizationalUnit -Name $subOU -Path $OUdn -ProtectedFromAccidentalDeletion $Protected
                    Write-Host "    [+] $subOU"
                }
            } 
            else {break}
            $index++
        }
    }
}

# $domain = (Get-ADDomain).Forest
$domainDN = (Get-ADRootDSE).rootDomainNamingContext

New-ADOrganizationalUnit -Name $model.RootOUName -Path $domainDN -ProtectedFromAccidentalDeletion $model.PreventOUDeletion
$RootOUdn = (Get-ADOrganizationalUnit -Filter * | Where-Object Name -eq $model.RootOUName).DistinguishedName
Write-Host "[+] $($model.RootOUName)" -ForegroundColor Green

New-OUsGeneration -ParentOU $RootOUdn -model_in ($model.UsersBaseOU) -Protected $model.PreventOUDeletion
New-OUsGeneration -ParentOU $RootOUdn -model_in ($model.ComputersOUs) -Protected $model.PreventOUDeletion
New-OUsGeneration -ParentOU $RootOUdn -model_in ($model.SecGroupsOUs) -Protected $model.PreventOUDeletion
New-OUsGeneration -ParentOU $RootOUdn -model_in ($model.CustomOUs) -Protected $model.PreventOUDeletion -Custom

