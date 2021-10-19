
Clear-Host
Remove-Variable * -ErrorAction SilentlyContinue

(Get-Host).UI.RawUI.ForegroundColor = "Green"

#Импортируем модуль с функциями работы с Jira Insight
Import-Module PSJiraInsight -Verbose

#################   Соединяемся с Jira и vCenter    #################
$UserName = "zzz-cmdb"
$JiraServer = "https://sd."

#Сохранить шифрованный пароль в файл
$KeyFile = "C:\Scripts\VMware\AES.key"
$PasswordFile = "C:\Scripts\VMware\Password.txt"

#Сохраняем ключ в файл AES.key (1 раз)
#$Key = New-Object Byte[] 16   # You can use 16 (128-bit), 24 (192-bit), or 32 (256-bit) for AES
#[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
#$Key | Out-File $KeyFile

$Key = Get-Content $KeyFile

#Сохраняем пароль на основе ключа в файл Password.txt (1 раз)
#$Password = "PASSWORD" | ConvertTo-SecureString -AsPlainText -Force
#$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile

$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)

# Игнорим сертификат (один раз)
#Set-PowerCLIConfiguration -InvalidCertificateAction ignore

# Соединяемся с vCenter
Connect-VIServer -server zzz-srv-vca1 -Credential $Credentials

# Берем все данные из VM

$allVMs = Get-Cluster | Get-VM
$VMs = $allVMs #| Where {$_.Name -like "zzz-MES"} # Если надо обновить отдельный сервер!
$vmall = Get-View -ViewType Virtualmachine

#################   Обновление информации Operating System[zzz] в CMDB    #################

$SchemaName = "CMDB"
$ObjectTypeName = "Operating System[zzz]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

#Собираем массив ОС
$SchemaName = "CMDB"
$ObjectTypeName = "Operating System[zzz]"

#Собираем массив объектов из VM
$oss = @()
foreach ($vm in $VMs) {  
    if ($vm.Guest.OSFullName) {
        $os = New-Object -TypeName psobject
        $os | Add-Member -MemberType NoteProperty -Name Name -Value $vm.Guest.OSFullName
        $oss += $os
    }
}

#Обновляем объекты в Jira
foreach ($os in ($oss | Select-Object -Property Name -Unique)) {
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $os.Name }
    #echo $ObjectFromCMDB
    Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $os -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
}

#Массив ОС с ObjectKey (для обновления VM)
$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$osnames = @()
foreach ($ob in $objectList.objectEntries) {
    $osnames += [pscustomobject]@{name = $ob.name; objectKey = $ob.objectKey }
}
#echo $osnames

#################   Обновление информации VLANs[zzz] в CMDB    #################
# Нужно доработать!

$SchemaName = "CMDB"
$ObjectTypeName = "VLANs[zzz]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

$vlans = @()

#Собираем массив объектов из VM
foreach ($vm in $VMs) {

    $pgroup = Get-VirtualPortGroup -VM $vm

    $subnetmask = @()
    foreach ($iproute in $vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute) {
        if (($vm.Guest.IPAddress -replace "[0-9]$|[1-9][0-9]$|1[0-9][0-9]$|2[0-4][0-9]$|25[0-5]$", "0" | select -uniq) -contains $iproute.Network) {
            $sb = $iproute.Network + "/" + $iproute.PrefixLength
            $subnetmask += $sb | where { $_ -NotMatch ":" }
        }
    }
    $subnet = $subnetmask | select -uniq | Sort -Descending

    $i = 0
    foreach ($pg in $pgroup) {

        $vlan = New-Object -TypeName psobject
        #VM Name
        #$vlan | Add-Member -MemberType NoteProperty -Name VM -Value $vm.Name
                
        if ($pg.ExtensionData -is [VMware.Vim.DistributedVirtualPortgroup]) {
            if ($pg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId) {
                #Name
                $vlan | Add-Member -MemberType NoteProperty -Name Name -Value ($pg.Name).Substring(($pg.Name).Indexof("_") + 1)                

                #VLANID
                $vlan | Add-Member -MemberType NoteProperty -Name VLANID -Value $pg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId

                #Description
                $vlan | Add-Member -MemberType NoteProperty -Name Description -Value $pg.Notes
            }
            else {
                #Name
                $vlan | Add-Member -MemberType NoteProperty -Name Name -Value ($pg.Name).Substring(($pg.Name).Indexof("_") + 1)                

                #VLANID
                $vlan | Add-Member -MemberType NoteProperty -Name VLANID -Value $pg.ExtensionData.Config.DefaultPortConfig.Vlan.PvlanId

                #Description
                $vlan | Add-Member -MemberType NoteProperty -Name Description -Value $pg.Notes
            }
        }
        else {
            #Name
            $vlan | Add-Member -MemberType NoteProperty -Name Name -Value ($pg.Name).Substring(($pg.Name).Indexof("_") + 1)                

            #VLANID
            $vlan | Add-Member -MemberType NoteProperty -Name VLANID -Value $pg.VlanId

            #Description
            $vlan | Add-Member -MemberType NoteProperty -Name Description -Value $pg.Notes 
        }

        #Gateway
        if (($vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute.Gateway.IpAddress) -is [system.array]) {
            #$vlan | Add-Member -MemberType NoteProperty -Name Gateway -Value ($vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute.Gateway.IpAddress[$i] | where {$_ -ne $null} | select -uniq)
        }
        else {
            #$vlan | Add-Member -MemberType NoteProperty -Name Gateway -Value $vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute.Gateway.IpAddress
        }

        #Subnet
        if ($subnet -is [system.array]) {
            #$vlan | Add-Member -MemberType NoteProperty -Name Subnet -Value $subnet[$i] 
        }
        else {
            #$vlan | Add-Member -MemberType NoteProperty -Name Subnet -Value $subnet   
        }   

        $vlans += $vlan
        $i++
    }
}

#Обновляем объекты в Jira
foreach ($vlan in ($vlans | Select * -Unique)) {
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $vlan.Name }
    #echo $vlan
    #Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $vlan -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
}

#################   Обновление информации Virtual Machine[zzz] в CMDB    #################

$SchemaName = "CMDB"
$ObjectTypeName = "Virtual Machine[zzz]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

#Собираем массив объектов из VM
$vmObjects = @()
foreach ($vm in $VMs) {
    
    $vmx = $vmall | Where { $_.Name -like $vm.Name }

    # Получаем данные по текущему VM из Jira
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $vmObj.Name }

    $vmObj = New-Object -TypeName psobject

    #Name
    $vmObj | Add-Member -MemberType NoteProperty -Name Name -Value $vm.Name

    #Name
    $vmObj | Add-Member -MemberType NoteProperty -Name VM_ID -Value $vm.id

    #Description
    if (!($ObjectFromCMDB.attributes | where { $_.objectTypeAttributeId -like 245253 } | select -ExpandProperty objectAttributeValues)) {
        $vmObj | Add-Member -MemberType NoteProperty -Name Description -Value $vmx.Config.Annotation
    }

    #OS  
    $os = $osnames | where { $_.name -like $vm.Guest.OSFullName }
    $vmObj | Add-Member -MemberType NoteProperty -Name OS -Value $os.objectKey

    #DNS Name
    $vmObj | Add-Member -MemberType NoteProperty -Name "DNS Name" -Value $vmx.guest.hostname
    
    #VLANs
    #$vmObj | Add-Member -MemberType NoteProperty -Name "VLANs" -Value ""

    #IP address
    $vmObj | Add-Member -MemberType NoteProperty -Name "IP address" -Value ([string]::Join(',', ($vm.Guest.IPAddress | where { $_ -NotMatch ":" })))

    #DNS
    $vmObj | Add-Member -MemberType NoteProperty -Name DNS -Value ([string]::Join(',', ($vm.ExtensionData.Guest.IpStack.DnsConfig.IpAddress | where { $_ -ne $null -or $_ -NotMatch ":" })))

    #Gateway
    $vmObj | Add-Member -MemberType NoteProperty -Name Gateway -Value ([string]::Join(',', ($vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute.Gateway.IpAddress | where { $_ -ne $null } | select -uniq)))

    #Subnet
    $subnetmask = @()
    foreach ($iproute in $vm.ExtensionData.Guest.IpStack.IpRouteConfig.IpRoute) {

        if (($vm.Guest.IPAddress -replace "[0-9]$|[1-9][0-9]$|1[0-9][0-9]$|2[0-4][0-9]$|25[0-5]$", "0" | select -uniq) -contains $iproute.Network) {

            $subnetmask += $iproute.Network + "/" + $iproute.PrefixLength
        }
    }
    if ($subnetmask -is [system.array]) {
        $vmObj | Add-Member -MemberType NoteProperty -Name Subnet -Value ([string]::Join(',', ($subnetmask | where { $_ -NotMatch ":" })))
    }
    
    #vHDD
    $vmObj | Add-Member -MemberType NoteProperty -Name vHDD -Value ([math]::Round((($vmx.Summary.Storage.Committed) - ($vmx.summary.config.memorysizemb)) / 1Gb))

    #vCPU
    $vmObj | Add-Member -MemberType NoteProperty -Name vCPU -Value $vmx.summary.config.numcpu

    #vRAM
    $vmObj | Add-Member -MemberType NoteProperty -Name vRAM -Value (($vmx.summary.config.memorysizemb) / 1024)

    #Status
    if ($vmx.summary.runtime.powerState -eq "poweredOn") {
        $vmObj | Add-Member -MemberType NoteProperty -Name Status -Value 2
    }
    elseif ($vmx.summary.runtime.powerState -eq "poweredOff") {
        $vmObj | Add-Member -MemberType NoteProperty -Name Status -Value 6
    }
    else {
        $vmObj | Add-Member -MemberType NoteProperty -Name Status -Value ""
    }
    
    $vmObjects += $vmObj
}

#Обновляем объекты в Jira
foreach ($vmObj in $vmObjects) {
    #$ObjectFromCMDB = $objectList.objectEntries|?{$_.VM_ID -like $vmObj.VM_ID}
    #if(!$ObjectFromCMDB){
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $vmObj.Name }
    #}
    #echo $ObjectFromCMDB
    Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $vmObj -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
}

#################   Отмечаем удаленные (Deleted) Virtual Machine[zzz] в CMDB    #################

$SchemaName = "CMDB"
$ObjectTypeName = "Virtual Machine[zzz]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

# Массив из существующих VM
$vmnames = @()
$vmnames = $allVMs | Select -ExpandProperty Name
for ($i = 0; $i -lt $vmnames.Length; $i++) {
    $vmnames[$i] = $vmnames[$i].toUpper()
}

#Отмечаем удаленные
foreach ($ob in $objectList.objectEntries) {
    $obname = ($ob.attributes | where { $_.objectTypeAttributeId -like 245251 } | select -ExpandProperty objectAttributeValues | select -ExpandProperty value)
    $obnameUpper = $obname.ToUpper()   
    if (!($vmnames.Contains($obnameUpper))) {
        $vmObj = [pscustomobject]@{Name = "$obname"; Deleted = 'true'; Status = '6' }
        #echo $vmObj
        Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ob -DataFromVMWare $vmObj -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
    }
}