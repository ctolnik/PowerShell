#Функция поиска схемы по имени
function Get-InsightSchemas ($JiraServer, $SchemaName, $Credentials) {

    # Формируем заголовки строки подключения
    $headers = @{

        "Accept"        = "application/json"

        "Authorization" = "Basic"

    }

    $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/objectschema/list")

    # Получаем схемы из Insgiht
    # Если в функцию не передано имя искомой схемы, то ищем все доступные схемы
    if ($SchemaName -like $null) {
        Write-Host "Получаем все схемы Insight"
        try {
            $SchemasList = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"
        }
        catch {
            Write-Host "Ошибка в запросе "$Request.Uri
            return $null
        }
        if ($SchemasList.objectschemas.count -eq 0 -and $SchemasList -notlike $null) {
            Write-Host "Найдено схем: 1"
        }
        if ($SchemasList.objectschemas.count -eq 0 -and $SchemasList -like $null) {
            Write-Host "Найдено схем: 0"
        }
        if ($SchemasList.objectschemas.count -gt 0) {
            Write-Host "Найдено схем: "$SchemasList.objectschemas.count
        }
        return $SchemasList
    }
    # Если в функцию передано имя искомой схемы, то ищем эту схему по имени
    else {
        Write-Host "Получаем схему с именем $SchemaName"
        try {
            $SchemasList = (Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8").objectschemas | ? { $_.name -contains $SchemaName }
        }
        catch {
            Write-Host "Ошибка в запросе "$Request.Uri
            return $null
        }
        if ($SchemasList.objectschemas.count -eq 0 -and $SchemasList -notlike $null) {
            Write-Host "Найдено схем: 1"
        }
        if ($SchemasList.objectschemas.count -eq 0 -and $SchemasList -like $null) {
            Write-Host "Найдено схем: 0"
        }
        if ($SchemasList.objectschemas.count -gt 0) {
            Write-Host "Найдено схем: "$SchemasList.objectschemas.count
        }

        return $SchemasList
    }

}

#Функция поиска типов объектов по имени
function Get-ObjectTypes ($JiraServer, $SchemaName, $ObjectTypeName, $Credentials) {

    # Формируем заголовки строки подключения
    $headers = @{

        "Accept"        = "application/json"

        "Authorization" = "Basic"

    }

    $SchemaID = (Get-InsightSchemas -JiraServer $JiraServer -SchemaName $SchemaName -Credentials $Credentials).id

    $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/objectschema/$SchemaID/objecttypes/flat")

    # Получаем объекты из схемы $SchemaID
    # Если в функцию не передано имя типов объекта, то ищем все доступные типы объектов
    if ($ObjectTypeName -like $null) {
        Write-Host "Получаем все типы объектов Insight"
        try {
            $ObjectTypeList = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"
        }
        catch {
            Write-Host "Ошибка в запросе "$Request.Uri
            return $null
        }
        Write-Host "Найдено типов объектов: "$ObjectTypeList.count
        return $ObjectTypeList
    }
    # Если в функцию передано имя искомого типа объектов, то ищем этот тип объектов
    else {
        Write-Host "Получаем тип объектов $ObjectTypeName"
        try {
            $ObjectType = (Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8") | ? { $_.name -contains $ObjectTypeName }
        }
        catch {
            Write-Host "Ошибка в запросе "$Request.Uri
            return $null
        }
        Write-Host "Найдено типов объектов: "$ObjectType.count
        return $ObjectType
    }

}

#Функция поиска объектов по имени объекта или по имени типа объектов (имени раздела)
function Get-ObjectInsight ($JiraServer, $SchemaName, $ObjectTypeName, $ObjectName, $Credentials) {

    # Формируем заголовки строки подключения
    $headers = @{

        "Accept"        = "application/json"

        "Authorization" = "Basic"

    }

    #Проверка, что указан хотябы один из параметров $ObjectTypeName или $ObjectName
    if ($ObjectTypeName -notlike $null -or $ObjectName -notlike $null) {
    
        $SchemaID = $SchemaID = (Get-InsightSchemas -JiraServer $JiraServer -SchemaName $SchemaName -Credentials $Credentials).id

        #Если указано имя искомого объекта, то осуществляем поиск по нему
        if ($ObjectName -notlike $null) {
            Write-Host "Ищем объект с именем $ObjectName"
            $iql = 'Name like "' + $ObjectName + '"'
            $iqlrequest = $iql
            $iql = [System.Web.HttpUtility]::UrlEncode($iql)
            $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/iql/objects?objectSchemaId=" + $SchemaID + "&iql=" + $iql + "&resultPerPage=10000")
            Write-Host "Получаем объекты по IQL фильтру: $iqlrequest"
            try {
                $ObjectList = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"
            }
            catch {
                Write-Host "Ошибка в запросе "$Request.Uri
                return $null
            }
            Write-Host "Найдено объектов: "$ObjectList.objectEntries.Count
            return $ObjectList

        }
        #Если не указано имя искомого объекта, но указано имя типа объекта (имя раздела), то ищем все объекты в этом разделе
        else { 
            Write-Host "Ищем все объекты в разделе $ObjectTypeName"
            $ObjectTypeNameTemp = $ObjectTypeName
            $ObjectTypeName = [System.Web.HttpUtility]::UrlEncode($ObjectTypeName)
            $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/iql/objects?objectSchemaId=" + $SchemaID + "&iql=objectType=%22" + $ObjectTypeName + "%22&resultPerPage=10000")
            Write-Host "Получаем все объекты из $ObjectTypeNameTemp"
            try {
                $ObjectList = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"
            }
            catch {
                Write-Host "Ошибка в запросе "$Request.Uri
                return $null
            }
            Write-Host "Найдено объектов: "$ObjectList.objectEntries.Count
            return $ObjectList
        }
    }
    else {
        Write-Host "Не указаны параметры ObjectTypeName или ObjectName"
        return $null
    }

}

#Функция поиска объектов по фильтру IQL
function Get-ObjectIqlInsight ($JiraServer, $SchemaName, $iql, $Credentials) {

    # Формируем заголовки строки подключения
    $headers = @{

        "Accept"        = "application/json"

        "Authorization" = "Basic"

    }

    $SchemaID = $SchemaID = (Get-InsightSchemas -JiraServer $JiraServer -SchemaName $SchemaName -Credentials $Credentials).id

    $iqlrequest = $iql

    $iql = [System.Web.HttpUtility]::UrlEncode($iql)

    $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/iql/objects?objectSchemaId=" + $SchemaID + "&iql=" + $iql + "&resultPerPage=10000")
    #Write-Host "Готовим запрос "$Request.Uri

    Write-Host "Получаем объекты по IQL фильтру: $iqlrequest"
    try {
        $ObjectList = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"
    }
    catch {
        Write-Host "Ошибка в запросе "$Request.Uri
        return $null
    }
    Write-Host "Найдено объектов: "$ObjectList.objectEntries.Count
    return $ObjectList
}

#Функция поиска атрибутов объекта
function Get-ObjectAttributes ($JiraServer, $SchemaName, $ObjectName, $Credentials) {

    #Массив для хранения имени объекта и его атрибутов
    $arrayObjectsAttributes = @()

    # Формируем заголовки строки подключения
    $headers = @{

        "Accept"        = "application/json"

        "Authorization" = "Basic"

    }

    $iql = 'Name like "' + $ObjectName + '"'

    if ($ObjectName -notlike $null) {
        $ObjectList = Get-ObjectIqlInsight -JiraServer $JiraServer -SchemaName $SchemaName -iql $iql -Credentials $Credentials

        foreach ($GetObject in $ObjectList.objectEntries) {

            $id = $GetObject.id
            $ObjectName = $GetObject.name

            $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/object/$id/attributes")

            Write-Host "Получаем все атрибуты для объекта $ObjectName"
            try {
                $ObjectAttributes = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"       
                $Object = New-Object -TypeName psobject
                $Object | Add-Member -MemberType NoteProperty -Name ObjectName -Value $ObjectName
                $Object | Add-Member -MemberType NoteProperty -Name Attributes -Value $ObjectAttributes
                $arrayObjectsAttributes += $Object
            }
            catch {
                Write-Host "Ошибка в запросе "$Request.Uri
                return $null
            }
        }
    }
    else {
        Write-Host "Необходимо указать имя объекта в ObjectName"
        return $null
    }
    return $arrayObjectsAttributes
}

#Функция поиска атрибутов типа объекта
function Get-ObjectTypeAttributes ($JiraServer, $SchemaName, $ObjectTypeName, $Credentials) {

    #Массив для хранения имени объекта и его атрибутов
    $arrayObjectsTypeAttributes = @()
    # Формируем заголовки строки подключения
    $headers = @{

        "Accept"        = "application/json"

        "Authorization" = "Basic"

    }

    if ($ObjectTypeName -notlike $null) {
        $ObjectTypeList = Get-ObjectTypes -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials

        foreach ($GetObjectType in $ObjectTypeList) {

            $id = $GetObjectType.id
            $TypeName = $GetObjectType.name

            $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/objecttype/$id/attributes")

            Write-Host "Получаем все атрибуты для типа объекта (раздела) $TypeName"
            try {
                $ObjectTypeAttributes = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method GET -Uri $Request.Uri -ContentType "application/json;charset=utf-8"       
                $Object = New-Object -TypeName psobject
                $Object | Add-Member -MemberType NoteProperty -Name ObjectName -Value $TypeName
                $Object | Add-Member -MemberType NoteProperty -Name Attributes -Value $ObjectTypeAttributes
                $arrayObjectsTypeAttributes += $Object
            }
            catch {
                Write-Host "Ошибка в запросе "$Request.Uri
                return $null
            }
        }
    }
    else {
        Write-Host "Необходимо указать имя объекта в ObjectName"
        return $null
    }
    return $arrayObjectsTypeAttributes
}


<#
Объект $DataFromVMWarе должен иметь следующий вид: "Свойство" = "Значение"
Имя свойства доллжно совпадать с именем атрибута в CMDB

Имена свойств и описание значений:
Name = "DNS_ИМЯ_БЕЗ_ДОМЕНА"
Description = "ОПИСАНИЕ"
OS = "ИМЯ_ОС"
'DNS Name' = "ПОЛНОЕ_FQDN_ИМЯ_СЕРВЕРА"
VLANs = "VLAN_ID"
'IP address' = "IP_address"
vHDD = "ОБЪЕМ_ДИСКОВ_В_ГБ." #Каждый диск через пробел. Например 4 диска: 40 60 120 30
vCPU = "КОЛИЧЕСТВО_ЯДЕР_ЦПУ"
vRAM = "ОБЪЕМ_RAM_В_ГБ"
Status = "СТАТУС_МАШИНЫ" #Запущена, остановлена.

Пример:
$DataFromVMWare = New-Object -TypeName psobject
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Name -Value "zzz-PRINT02"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Description -Value "Сервис печати"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name OS -Value "76913"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name "DNS Name" -Value "zzz-PRINT02.zzz.local"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name VLANs -Value "300"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name "IP address" -Value "10.25.30.5"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name vHDD -Value "60"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name vCPU -Value "2"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name vRAM -Value "4"
$DataFromVMWare | Add-Member -MemberType NoteProperty -Name Status -Value "Running"
#>

#Функция обновления данных объекта Insight
#На вход подается объект ObjectFromCMDB полученный путем функции Get-ObjectInsight и извлечения оттуда нужного объекта из .objectEntries.
#В объект ObjectTypeAttributeList подается перечень родительских атрибутов с идентификаторами, полученый функцией Get-ObjectInsight и извлченным оттуда свойством .objectTypeAttributes.
#В объект $ObjectTypeName подается имя раздела, к примеру Vitrual Machine[zzz], где планируется создавать\изменять объекты
#Формат объекта DataFromVMWare описан выше.
function Update-ObjectInsight ($JiraServer, $ObjectFromCMDB, $DataFromVMWare, $ObjectTypeAttributeList, $ObjectTypeName, $Credentials) {
    Write-Host "Исполнение функции обновления"


    #Готовим строку API в формате Web

    #Выполняем запрос на обновление объекта с идентификатором $id и данными из $DataFromVMWare
    try {
        if ($ObjectFromCMDB -notlike $null) {
            # Формируем заголовки строки подключения
            $headers = @{

                "Accept"        = "application/json"

                "Authorization" = "Basic"

            } 
            #Берем идентификатор объекта, чтобы использовать его в REST-запросе
            Write-Host "Берем идентификатор объекта "$ObjectFromCMDB.name
            $id = $ObjectFromCMDB.id
            Write-Host "Формируем тело запроса для обновления объекта "$ObjectFromCMDB.ObjectName
            #Формируем данные в JSON, чтобы загрузить из VMWare в объект CMDB
            $payload = Create-Payload -ObjectFromCMDB $ObjectFromCMDB -ObjectTypeAttributeList $ObjectTypeAttributeList -DataFromVMWare $DataFromVMWare
            Write-Host "Готовим строку запрос для изменения объекта "$ObjectFromCMDB.name
            $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/object/$id")
            Write-Host "Выполненяем запрос для изменения объекта "$ObjectFromCMDB.name
            $result = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method PUT -Uri $Request.Uri -Body $payload -ContentType "application/json;charset=utf-8"
        }
        else {
            # Формируем заголовки строки подключения
            $headers = @{

                "Accept"        = "application/json"

                "Authorization" = "Basic"

            } 
            #Формируем данные в JSON, чтобы загрузить из VMWare в объект CMDB
            $payload = Create-Payload -ObjectFromCMDB $ObjectFromCMDB -ObjectTypeAttributeList $ObjectTypeAttributeList -ObjectTypeName $ObjectTypeName -DataFromVMWare $DataFromVMWare

            Write-Host "Готовим строку запрос для создания объекта "$ObjectFromCMDB.name
            $Request = [System.UriBuilder]($JiraServer + "/rest/insight/1.0/object/create")
            Write-Host "Выполненяем запрос для создания объекта "$ObjectFromCMDB.name
            
            Write-Host $headers
            Write-Host $Request.Uri
            Write-Host $payload
            $result = Invoke-RestMethod -Credential $Credentials -Headers $headers -Method POST -Uri $Request.Uri -Body $payload -ContentType "application/json;charset=utf-8"

        }
    }
    catch {
        Write-Host "Ошибка в запросе: "$Error[0].ErrorDetails.Message
        return $null
    }
    return $result
}

#Функция подготовки тела JSON для обновления данных объекта в Insight
function Create-Payload ($DataFromVMWare, $ObjectFromCMDB, $ObjectTypeAttributeList, $ObjectTypeName) {  
    
    $arrayOfAttrib = @()

    foreach ($property in $DataFromVMWare.PSObject.Properties) {
    
        if ( ($attribID = $ObjectTypeAttributeList | ? { $_.name -like $property.Name } | select id).id -notlike $null) {

            $AttribValueArray = @()
            $AttribValue = New-Object -TypeName psobject
            $AttribValue | Add-Member -MemberType NoteProperty -Name value -Value $property.Value
            $AttribValueArray += $AttribValue

            $attrib = New-Object -TypeName psobject
            $attrib | Add-Member -MemberType NoteProperty -Name objectTypeAttributeId -Value $attribID.id.ToString()
            $attrib | Add-Member -MemberType NoteProperty -Name objectAttributeValues -Value $AttribValueArray

            $arrayOfAttrib += $attrib
    
        }
    }
    
    $JSON = New-Object -TypeName psobject
    if ($ObjectTypeName -notlike $null) {
        $ObjectTypeID = (Get-ObjectTypes -JiraServer $JiraServer -SchemaName $SchemaName -ObjectTypeName $ObjectTypeName -Credentials $Credentials).id.ToString()
        $JSON | Add-Member -MemberType NoteProperty -Name objectTypeId -Value $ObjectTypeID
    }
    $JSON | Add-Member -MemberType NoteProperty -Name attributes -Value $arrayOfAttrib
    return ConvertTo-Json $JSON -Depth 10
}
