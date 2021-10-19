#Импортируем модуль с функциями работы с Jira Insight
Import-Module .\PSJiraInsight.psm1

#Указываем web-адрес сервера Jira в формате https://name.domain.ru
$JiraServer = ""

#Указываем учетные данные для входа на сервер Jira
$UserName = "USERANAME"
# Преобразуем зашифрованные стандартные строки в защищенные строки.
$SecurePassword = "PA$$W0RD" | ConvertTo-SecureString -AsPlainText -Force
# Сохраним имя пользователя и пароль в соответствующие поля экземпляра объекта PSCredential (централизованный способ управления именами пользователей)
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

#Указываем имя схемы Insight, с которой хотим работать
$SchemaName = "CMDB"

$ObjectTypeName = "Virtual Machine[zzz]"

#Запрос на языке IQL для поиска в Jira Insight
$iql = 'Object = "Windows Server 2008 R2 (64-bit)"'


#Примеры запросов
#Получить все объекты по фильтру IQL
$objects = Get-ObjectIqlInsight -JiraServer $JiraServer -SchemaName $SchemaName -iql $iql -Credentials $Credentials

#Получить все атрибуты и значения объекта zzz-PRIN02, по имени объекта
$attr = Get-ObjectAttributes -JiraServer $JiraServer -SchemaName $SchemaName -ObjectName "zzz-PRINT02" -Credentials $Credentials

#Получить схему с именем CMDB, если не указать схему - найдет все всхемы.
$schemas = Get-InsightSchemas -JiraServer $JiraServer -Credentials $Credentials -SchemaName "CMDB"

#Получить тип объектов (раздел) Virtual Machine[zzz] и все атрибуты данного типа объекта
$objtype = Get-ObjectTypes -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName "Virtual Machine[zzz]" -Credentials $Credentials

#Получить все типы объектов схемы
$objtype = Get-ObjectTypes -JiraServer $JiraServer -SchemaName $SchemaName -Credentials $Credentials

#Получить все объекты в разделе "Virtual Machine[zzz]"
$allobj = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName "Virtual Machine[zzz]" -Credentials $Credentials

#Получить объект по имени "zzz-PRINT02"
$allobj = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectName "zzz-PRINT02_TEST" -Credentials $Credentials

#Получить атрибуты и значения атрибутов для типа объектов (раздела) "Virtual Machine[zzz]"
$objTypeAttr = Get-ObjectTypeAttributes -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName "Virtual Machine[zzz]" -Credentials $Credentials







#Пример запроса на обновление информации о VLAN в CMDB

#Указываем web-адрес сервера Jira в формате https://name.domain.ru
$JiraServer = "https://sd..ru"

#Указываем учетные данные для входа на сервер Jira
$UserName = "USERANEM"
# Преобразуем зашифрованные стандартные строки в защищенные строки.
$SecurePassword = "PA$$W0RD" | ConvertTo-SecureString -AsPlainText -Force
# Сохраним имя пользователя и пароль в соответствующие поля экземпляра объекта PSCredential (централизованный способ управления именами пользователей)
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

#Указываем имя схемы Insight, с которой хотим работать
$SchemaName = "CMDB"

#Указываем раздел дл поиска объектов для их обновления или создания
$ObjectTypeName = "VLANs[zzz]"

#Готовим данные в объекте, которые хотим добавить в CMDB.
#Наименование свойств должны быть такими же как наименование атрибутов объекта в CMDB
#Для атрибутов, которые ссылаются на другой объект CMDB, их значение должно быть Key (Например для локации "Заводоуправление": CMDB-77290)
$DataFromVMWare = New-Object -TypeName psobject
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Name -Value "MCT_VLAN_Test"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Description -Value "Тестовый VLAN"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Gateway -Value "10.26.238.1"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Subnet -Value "10.26.238.0/28"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Location -Value "CMDB-77290"


#Запрашиваем все объекты данного типа (раздела VLANs[zzz]), чтобы проверять в будщем существует ли необходиый нам объект для обновления
$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials

#СОхраняем в переменную схему атрибутов, чтобы потом на ее основе подготовить структуру JSON для обновления
$ObjectTypeAttributeList = $objectList.objectTypeAttributes


#Берем имя этого объекта $ObjectFromCMDB. Если объекта с таким именем в CMDB нет,то значечние $ObjectFromCMDB = $null
$ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $DataFromVMWare.Name }
#Создаем запрос на обновление/создание объекта
#Если объекта нет, то он будет создан. Если объект в CMDB есть - то он будет обновлен
#пеиредаем имя объекта CMDB, которы нужно обновить $ObjectFromCMDB, данные для обновления $DataFromVMWare, схему атрибутов объекта $ObjectTypeAttributeList, имя типа объектов (раздела) $ObjectTypeName
Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $DataFromVMWare -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials






#Пример для обновления виртуальной машины

$JiraServer = "https://sd.zzz.ru"
$UserName = "USERNAME"
$SecurePassword = "PA$$W0RD" | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

$SchemaName = "CMDB"
$ObjectTypeName = "Virtual Machine[zzz]"

$DataFromVMWare = New-Object -TypeName psobject
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Name -Value "zzz-PRINT02_TEST"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Description -Value "Сервис печати"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name OS -Value "CMDB-76926"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name "DNS Name" -Value "zzz-PRINT02.zzz.local"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name VLANs -Value "CMDB-110717"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name "IP address" -Value "10.25.30.5"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name vHDD -Value "60"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name vCPU -Value "2"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name vRAM -Value "4"
#Для статуса ВМ необходимо передавать значение в цифровом виде:
#Если машина запущена Status=2, если не запущена Status=6
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Status -Value "2"
#Признак удалена ВМ или нет. true - удалена, false - не удалена. Значения с маленькой буквы.
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Deleted -Value "false"
#Дата удаления машины, либо $null если машина не удалена, либо дата-время в формате "dd.MM.yyyy HH:mm"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name "Deletion date" -Value $null
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name "Deletion date" -Value (Get-Date).ToString("dd.MM.yyyy HH:mm")

$objectList = Get-ObjectInsight -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials
$ObjectTypeAttributeList = $objectList.objectTypeAttributes

$ObjectFromCMDB = $objectList.objectEntries | ? { $_.name -like $DataFromVMWare.Name }
Update-ObjectInsight -JiraServer $JiraServer -ObjectFromCMDB $ObjectFromCMDB -DataFromVMWare $DataFromVMWare -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -Credentials $Credentials
