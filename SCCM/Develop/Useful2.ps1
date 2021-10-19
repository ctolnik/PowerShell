Import-Module activedirectory
Import-Module "C:\Scripts\Modules\SCCM\ConfigurationManager.psd1"

New-PSDrive -Name zzz -PSProvider "AdminUI.PS.Provider\CMSite" -Root "zzz-srv-sccm1.zzz" -Description "SCCM Site"
Remove-PSDrive -Name zzz

$HR = Get-ADComputer -SearchBase "OU=Отдел кадров,OU=zzz,OU=Domain Computers,DC=zzz,DC=zzz" -Filter * -Properties Name 
$HR.Name 
$collectionname = "zzz.HR.Systems"

Get-ChildItem zzz:
Set-location zzz:

New-CMDeviceCollection -Name $collectionname -LimitingCollectionName "zzz Workstations"

foreach ($Server in $HR.Name ) {
    try {
        Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $collectionname -ResourceId $(get-cmdevice -Name $Server).ResourceID
    }
    catch {
        "Invalid client or direct membership rule may already exist: $Server" 
    }
}


get-cmdevice -Name zzz1725