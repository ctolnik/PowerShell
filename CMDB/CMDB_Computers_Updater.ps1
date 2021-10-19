
CLEAR
Remove-Variable * -ErrorAction SilentlyContinue

(Get-Host).UI.RawUI.ForegroundColor = "White"

#Импортируем модуль с функциями работы с Jira Insight
Import-Module PSJiraInsight -Verbose

#################   Готовим подключение с Jira #################
$UserName = ""
$JiraServer = ""

#Сохранить шифрованный пароль в файл
$KeyFile = "C*\AES.key"
$PasswordFile = "C:\*\Password.txt"

#Сохраняем ключ в файл AES.key (1 раз)
#$Key = New-Object Byte[] 16   # You can use 16 (128-bit), 24 (192-bit), or 32 (256-bit) for AES
#[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
#$Key | Out-File $KeyFile

$Key = Get-Content $KeyFile

#Сохраняем пароль на основе ключа в файл Password.txt (1 раз)
#$Password = "PASSWORD" | ConvertTo-SecureString -AsPlainText -Force
#$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile

$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)

#################   Получаем данные о компьютерах из Hardware Inventory базы данных SCCM   #################

# Считываем SQL запрос из файла
# (!) При считывании через Get-Content вылетает ошибка синтаксиса SQL, поэтому считываю через StreamReader 
$FileStreamReader = New-Object System.IO.StreamReader("C:\Scripts\CMDB\CMDB_Computers_Updater\SQLQueryToSCCM.sql")
$SqlQuery = $FileStreamReader.ReadToEnd()

### Соединяемся с SQL сервером

$DBServer = "xxx-SRV-SCCM1"
$databasename = "CM_xxx"
$Connection = new-object system.data.sqlclient.sqlconnection # Объект подключения к базе данных SQL
$Connection.ConnectionString = "server=$DBServer;database=$databasename;Trusted_Connection=True" # Параметр Connectiongstring для базы данных
Write-host "Connection Information:"  -foregroundcolor yellow -backgroundcolor black
$Connection # Список информации о подключении

### Подключаемся к базе данных и выполняем SQL запрос

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand # Объект для команд sql

$Connection.Open()
Write-host "Connection to database successful." -ForegroundColor Green -BackgroundColor Black
$SqlCmd.CommandText = $SqlQuery
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$SqlCmd.Connection = $Connection
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$Connection.Close()
$query_data = $DataSet.Tables[0]


#################   Обновление информации Vendors[xxx] в CMDB   #################

# Собираем массив Vendor
$SchemaName = "CMDB"
$ObjectTypeName = "Vendors[xxx]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

# Собираем массив объектов из SQL Query
$vendors = @()
foreach ($c in $query_data) {  
    if ($c.deviceVENDor) {
        $vendor = New-Object -TypeName psobject
        $vendor | Add-Member -MemberType NoteProperty -Name Name -Value $c.deviceVENDor
        $vendors += $vendor
    }
}

# Обновляем объекты в Jira
foreach ($vendor in ($vendors | Select-Object -Property Name -Unique)) {
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $vendor.Name }
    #echo $ObjectFromCMDB
    Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $vendor -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
}

#Массив Vendors с ObjectKey (для обновления CMDB)
$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$vendor_names = @()
foreach ($ob in $objectList.objectEntries) {
    $vendor_names += [pscustomobject]@{name = $ob.name; objectKey = $ob.objectKey }
}

#################   Обновление информации Operating System[xxx] в CMDB   #################

# Собираем массив ОС
$SchemaName = "CMDB"
$ObjectTypeName = "Operating System[xxx]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

# Собираем массив объектов из SQL Query
$oss = @()
foreach ($c in $query_data) {  
    if ($c.OS) {
        $os = New-Object -TypeName psobject
        $os | Add-Member -MemberType NoteProperty -Name Name -Value $c.OS
        $oss += $os
    }
}

# Обновляем объекты в Jira
foreach ($os in ($oss | Select-Object -Property Name -Unique)) {
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $os.Name }
    #echo $ObjectFromCMDB
    Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $os -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
}

#Массив ОС с ObjectKey
$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$osnames = @()
foreach ($ob in $objectList.objectEntries) {
    $osnames += [pscustomobject]@{name = $ob.name; objectKey = $ob.objectKey }
}

#################   Обновление информации Computers[xxx] в CMDB    #################

$SchemaName = "CMDB"
$ObjectTypeName = "Computers[xxx]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

$update_data = @()
foreach ($q_data in $query_data) {
    $up_data = New-Object -TypeName psobject

    #Name
    $up_data | Add-Member -MemberType NoteProperty -Name Name -Value $q_data.deviceName #

    #Vendor Motherboard
    $vendor = $vendor_names | ? { $_.name -like $q_data.deviceVENDor }
    $up_data | Add-Member -MemberType NoteProperty -Name "Vendor Motherboard" -Value $vendor.objectKey #

    #Model Motherboard
    $up_data | Add-Member -MemberType NoteProperty -Name "Model Motherboard" -Value $q_data.deviceModel #

    #Serial Number Motherboard
    $up_data | Add-Member -MemberType NoteProperty -Name "Serial Number Motherboard" -Value $q_data.serialNumber#

    #Device Type
    $up_data | Add-Member -MemberType NoteProperty -Name "Device Type" -Value $q_data.DeviceType #

    #OS
    $os = $osnames | ? { $_.name -like $q_data.OS }  
    $up_data | Add-Member -MemberType NoteProperty -Name OS -Value $os.objectKey #
  
    #CPU Model
    $up_data | Add-Member -MemberType NoteProperty -Name "CPU Model" -Value $q_data.CPUModel #

    #Model VGA
    $up_data | Add-Member -MemberType NoteProperty -Name "Model VGA" -Value $q_data.VGAModel #
  
    #DNS Name
    $up_data | Add-Member -MemberType NoteProperty -Name "DNS Name" -Value $q_data.deviceName #

    #IP-Address
    $up_data | Add-Member -MemberType NoteProperty -Name "IP-Address" -Value $q_data.ipEthernet #

    #MAC-address Ethernet
    $up_data | Add-Member -MemberType NoteProperty -Name "MAC-address Ethernet" -Value $q_data.macEthernet #   

    #MAC-address WiFi
    if (($q_data.macWIreless) -notlike "") {
        $up_data | Add-Member -MemberType NoteProperty -Name "MAC-address WiFi" -Value $q_data.macWIreless #   
    }

    #Owner      
    if (($q_data.owner) -notlike "") {
        $up_data | Add-Member -MemberType NoteProperty -Name Owner -Value $q_data.owner #    
    }
    else {
        $up_data | Add-Member -MemberType NoteProperty -Name Owner -Value $UserName #      
    }
    ### DISK ###
    try {
        [array]$disks = ($q_data.HDDModel).Split(",")
    }
    catch [Exception] {
        Write-Host "catch Exception..." -ForegroundColor Red -BackgroundColor Black
        Write-Host ($_.Exception) -BackgroundColor Black
    }

    $i = 1
    foreach ($disk in $disks) {
        $dd = $disk.Split("|")
        #write-host "Disk $i $dd"
        #write-host $dd[0] -ForegroundColor Yellow -BackgroundColor Black
        $up_data | Add-Member -MemberType NoteProperty -Name "Model disk $i" -Value $dd[0] #
        #write-host $dd[1] -ForegroundColor Magenta -BackgroundColor White
        $up_data | Add-Member -MemberType NoteProperty -Name "Type disk $i" -Value $dd[1] #
        #write-host $dd[2] -ForegroundColor Blue -BackgroundColor White
        $up_data | Add-Member -MemberType NoteProperty -Name "Value disk $i" -Value $dd[2] #
        $i++
    }

    ### RAM ###
    try {
        [array]$mems = ($q_data.modelMemory).Split(",")
    }
    catch [Exception] {
        Write-Host "catch Exception..." -ForegroundColor Red -BackgroundColor Black
        Write-Host ($_.Exception) -BackgroundColor Black
    }

    $i = 1
    $Value_RAM = 0
    foreach ($mem in $mems) {
        $mm = $mem.Split("|")
        #write-host "Memory $i $mm"
        #write-host $mm[0] -ForegroundColor Yellow -BackgroundColor Black
        $up_data | Add-Member -MemberType NoteProperty -Name "Model RAM unit $i" -Value $mm[0] #
        #write-host $mm[1] -ForegroundColor Magenta -BackgroundColor White
        $up_data | Add-Member -MemberType NoteProperty -Name "Value RAM unit $i" -Value $mm[1] #

        $Value_RAM = $Value_RAM + $mm[1] 

        $i++
    }

    #Value RAM
    $up_data | Add-Member -MemberType NoteProperty -Name "Value RAM" -Value $Value_RAM #Общий объем RAM, ГБ

    $update_data += $up_data

}

#Обновляем объекты в Jira
foreach ($computer in $update_data) {
    $ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $computer.Name }    
    Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $computer -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
}

#################   Отмечаем IsDeployed для Computers[xxx] в CMDB    #################

$SchemaName = "CMDB"
$ObjectTypeName = "Computers[xxx]"

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes
$objectEntriesList = $objectList.objectEntries

#Получить атрибуты и значения атрибутов для типа объектов (раздела) "Computers[xxx]"
$objTypeAttr = Get-ObjectTypeAttributes -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$IsDeployed_id = ($objTypeAttr.Attributes | ? { $_.name -eq "IsDeployed" }).id

# Массив из существующих Computers[xxx]
$computers = @()
$computers = $query_data.deviceName
for ($i = 0; $i -lt $computers.Length; $i++) {
    $computers[$i] = $computers[$i].toUpper()
}

#Отмечаем "В Эксплуатации" или "На складе"/ "Снято с мониторинга" ставится вручную
foreach ($object in $objectEntriesList) {
    $obnameUpper = ($object.name).ToUpper()
    
    $IsDeployed_value = (($object.attributes | ? { $_.objectTypeAttributeId -eq $IsDeployed_id }).objectAttributeValues).value
    
    if (!($IsDeployed_value -eq "Снято с мониторинга")) {
        if ($computers.Contains($obnameUpper)) {
            $IsDeployedObj = [pscustomobject]@{IsDeployed = 'В эксплуатации' }            
        }
        else {
            $IsDeployedObj = [pscustomobject]@{IsDeployed = 'На складе' }             
        }
        Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $object -DataFromVMWare $IsDeployedObj -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
    }
}