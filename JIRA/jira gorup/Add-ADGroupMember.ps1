clear
Import-Module ActiveDirectory

# Проверяем настройки запрета на запуск скриптов
Get-ExecutionPolicy

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"

# Включаем логирование
Start-Transcript -path ("C:\LOGS\jiragroup\log_{0:yyyy-MM-dd_hh-mm}.log" -f (get-date)) -append

# Останавливаем скрипт при первой ошибке
#$ErrorActionPreference = 'Stop'

# --------START--------
# Скрипт добавления пользователей в группу WF-Developers (Агенты портала "Оружейное производство")

$OU = "OU=100,OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=WF-Developers,OU=WF,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
	    Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей в группу ktcopp-users (Пользователи проекта "КТЦ ОПП")

$OU = "OU=040,OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=ktcopp-users,OU=KTCOPP,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
	    Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей ИМЗ в группу SD-Users-IMZ (Пользователи Jira по умолчанию для ИМЗ)

$OU = "OU=Пользователи,OU=Механический завод,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-IMZ,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей ММЗ в группу SD-Users-MMZ (Пользователи Jira по умолчанию для ММЗ)

$OU = "OU=Пользователи,OU=ММЗ,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-MMZ,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
    Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей РСО в группу SD-Users-RSO (Пользователи Jira по умолчанию для РСО)

$OU = "OU=Пользователи,OU=ООО Русское Стрелковое Оружие,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-RSO,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
	
# --------END--------

# --------START--------
# Скрипт добавления пользователей ООО "Инструмент-Д" в группу SD-Users-Instrument-D (Пользователи Jira по умолчанию для ООО "Инструмент-Д")

$OU = "OU=Пользователи,OU=Инструмент-Д,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Instrument-D,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей АО "Рыбинская Верфь" в группу SD-Users-Rybinskshipyard (Пользователи Jira по умолчанию для АО "Рыбинская Верфь")

$OU = "OU=Пользователи,OU=АО Рыбинская верфь,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Rybinskshipyard,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления Поставщиков в группу "LG-8D Team" 

$OU = "OU=Поставщики,OU=Аутсорс,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=LG-8D Team,OU=LG,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления Поставщиков в группу "LGPLUS-8D Team" 

$OU = "OU=Поставщики,OU=Аутсорс,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=LGPLUS-8D Team,OU=LG,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей группы 99 в группу "SD-Users-Group99" 

$OU = "OU=Пользователи,OU=Группа99,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Group99,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей ТКХ в группу "SD-Users-TKH" 

$OU = "OU=Пользователи,OU=ООО ТрансКомплектХолдинг,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-TKH,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей ООО "Верфь братьев Нобель" в группу SD-Users-VBM (Пользователи Jira по умолчанию для ООО "Верфь братьев Нобель")

$OU = "OU=Пользователи,OU=ООО Верфь братьев Нобель,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-VBM,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей ООО "Системная Интеграция" в группу SD-Users-SystemIntegrator (Пользователи Jira по умолчанию для ООО "Системный Интегратор")

$OU = "OU=Пользователи,OU=Системная Интеграция,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-SystemIntegrator,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей ИЦКК в группу SD-Users-ITSKK (Пользователи Jira по умолчанию для ИЦКК)

$OU = "OU=Пользователи,OU=Инновационный центр Концерна Калашников,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-ITSKK,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей АО "Судостроительный завод Вымпел" в группу SD-Users-Vympel (Пользователи Jira по умолчанию для АО "Судостроительный завод Вымпел")

$OU = "OU=Пользователи,OU=АО Судостроительный завод Вымпел,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Vympel,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей "Военное представительство" в группу SD-Users-WAR (Пользователи Jira по умолчанию для "Военное представительство")

$OU = "OU=Военное представительство,OU=Аутсорс,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-WAR,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт добавления пользователей АО "Концерн "Калашников" в группу SD-Users (Пользователи Jira по умолчанию для АО "Концерн "Калашников")

$OU = "OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU не находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add count '"$userOutGroup.count"'"

	# Если какие то пользователи находящиеся в $OU не входят в группу $GR, то добавляем их в группу $GR
	if ($userOutGroup.count -ne 0) {
		Add-ADGroupMember -Identity $group -Members $userOutGroup
	    $userOutGroup.name
	}
	Write-Host "-----"

	# Получаем всех пользователей группы $GR (Учитыва уже изменения, если они были)
	[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
	# Сравниваем список всех пользователей группы $GR со списком ползователей из $OU находящихся в группе. Получаем разницу, т.е. пользователей которые в группе $GR но не в $OU.
	$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
	Write-Host "Delete count '"$diff.count"'"

	# Если какие то пользователи были перемещены из $OU, удаляем из группы.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Добавление новых групп в Jira 

$OU = "OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=JiraGroupSD,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем группы из $OU не находящихся в группе $GR
	[array]$Members = Get-ADGroup -SearchBase $OU –LDAPFilter "((&(objectCategory=group)(SamAccountName=DM-*)(!memberOf=$($group.DistinguishedName))))"
	Write-Host "Add new group count '"$Members.count"'"

	# Добавляем новые группы $Members в группу $GR
	if ($Members.count -ne 0) {
	    Add-ADGroupMember -Identity $group -Members $Members
		$Members.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт удаления пользователей из группы LG-Transport в случае присутствия в ней сотрудников департамента 726/087

$OU = "OU=087,OU=726,OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=LG-Transport,OU=LG,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$OU
$GR
Write-Host "-----"

try {
	# Получаем группу $GR
	$group = Get-ADGroup -Identity $GR
	Write-Host "----- Group '"$group.name"' -----"

	# Получаем пользователей из $OU находящихся в группе $GR
	[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "(memberOf=$($group.DistinguishedName))"
	Write-Host "Delete count '"$userOutGroup.count"'"

	# Удаляем пользователей из группы, если это пользователи $OU.
	if ($userOutGroup.count -ne 0) {
	    Remove-ADGroupMember -Identity $group -Members $userOutGroup -Confirm:$false
	    $userOutGroup.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# --------START--------
# Скрипт удаления пользователей из группы RINT-Developers в случае присутствия в ней сотрудников из группы RINT-NotDevelopers

$GR1 = "CN=RINT-NotDevelopers,OU=RINT,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR2 = "CN=RINT-Developers,OU=RINT,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

Write-Host ""
Write-Host "--------------- START ---------------"
$GR1
$GR2
Write-Host "-----"

try {
	$group1 = Get-ADGroup -Identity $GR1
	$group2 = Get-ADGroup -Identity $GR2
	Write-Host "----- Group '"$group2.name"' -----"

	[array]$userInGroup1 = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group1.DistinguishedName))))"
	[array]$userInGroup2 = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group2.DistinguishedName))))"

	[array]$diff = $userInGroup1 | where {$userInGroup2.name -contains $_.name}
	Write-Host "Delete count '"$diff.count"'"

	# Удаляем пользователей из группы $GR2, если это пользователи группы $GR1.
	if ($diff.count -ne 0) {
		Remove-ADGroupMember -Identity $group2 -Members $diff -Confirm:$false
	    $diff.name
	}
	Write-Host "--------------- END ---------------"
}
catch {
    Write-Host "Предупреждение: $_"
    Write-Host "--------------- END ---------------"
}
# --------END--------

# Выключаем логирование
Stop-Transcript