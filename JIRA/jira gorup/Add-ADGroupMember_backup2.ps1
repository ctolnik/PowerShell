Import-Module ActiveDirectory
# Скрипт добавления пользователей в группу WF-Developers (Агенты портала "Оружейное производство")

$OU = "OU=100,OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=WF-Developers,OU=WF,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
    Add-ADGroupMember -Identity $group -Members $userOutGroup
    
}

# Скрипт добавления пользователей в группу ktcopp-users (Пользователи проекта "КТЦ ОПП")

$OU = "OU=040,OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=ktcopp-users,OU=KTCOPP,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
    Add-ADGroupMember -Identity $group -Members $userOutGroup
}

# Скрипт добавления пользователей ИМЗ в группу SD-Users-IMZ (Пользователи Jira по умолчанию для ИМЗ)

$OU = "OU=Пользователи,OU=Механический завод,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-IMZ,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}


# Скрипт добавления пользователей ММЗ в группу SD-Users-MMZ (Пользователи Jira по умолчанию для ММЗ)

$OU = "OU=Пользователи,OU=ММЗ,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-MMZ,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей ООО "Инструмент-Д" в группу SD-Users-Instrument-D (Пользователи Jira по умолчанию для ООО "Инструмент-Д")

$OU = "OU=Пользователи,OU=Инструмент-Д,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Instrument-D,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей АО "Рыбинская Верфь" в группу SD-Users-Rybinskshipyard (Пользователи Jira по умолчанию для АО "Рыбинская Верфь")

$OU = "OU=Пользователи,OU=АО Рыбинская верфь,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Rybinskshipyard,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления Поставщиков в группу "LG-8D Team" 

$OU = "OU=Поставщики,OU=Аутсорс,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=LG-8D Team,OU=LG,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления Поставщиков в группу "LGPLUS-8D Team" 

$OU = "OU=Поставщики,OU=Аутсорс,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=LGPLUS-8D Team,OU=LG,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления Поставщиков в группу "service-desk-agents" 

$OU = "OU=Поставщики,OU=Аутсорс,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=service-desk-agents,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей ООО "Верфь братьев Нобель" в группу SD-Users-VBM (Пользователи Jira по умолчанию для ООО "Верфь братьев Нобель")

$OU = "OU=Пользователи,OU=ООО Верфь братьев Нобель,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-VBM,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей ООО "Системная Интеграция" в группу SD-Users-SystemIntegrator (Пользователи Jira по умолчанию для ООО "Системный Интегратор")

$OU = "OU=Пользователи,OU=Системная Интеграция,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-SystemIntegrator,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей ИЦКК в группу SD-Users-ITSKK (Пользователи Jira по умолчанию для ИЦКК)

$OU = "OU=Пользователи,OU=Инновационный центр Концерна Калашников,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-ITSKK,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей АО "Судостроительный завод Вымпел" в группу SD-Users-Vympel (Пользователи Jira по умолчанию для АО "Судостроительный завод Вымпел")

$OU = "OU=Пользователи,OU=АО Судостроительный завод Вымпел,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users-Vympel,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Скрипт добавления пользователей АО "Концерн "Калашников" в группу SD-Users (Пользователи Jira по умолчанию для АО "Концерн "Калашников")

$OU = "OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=SD-Users,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(!memberOf=$($group.DistinguishedName))))"
[array]$userInGroup = Get-ADUser -SearchBase "DC=npo,DC=izhmash" –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
[array]$userInGroupOU = Get-ADUser -SearchBase $OU –LDAPFilter "((&(objectCategory=person)(objectClass=user)(memberOf=$($group.DistinguishedName))))"
$diff = Compare-Object -ReferenceObject ($userInGroup) -DifferenceObject ($userInGroupOU) -PassThru
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
	Add-ADGroupMember -Identity $group -Members $userOutGroup
}
Write-Host "Name '"$group.name"', delete count '"$diff.count"'"
if ($diff.count -ne 0) {
	Remove-ADGroupMember -Identity $group -Members $diff -Confirm:$false
}

# Добавление новых групп в Jira 

$OU = "OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=JiraGroupSD,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity JiraGroupSD
$Memers = Get-ADGroup -SearchBase $OU –LDAPFilter '(&(SamAccountName=DM-*)(!memberOf=$($group.DistinguishedName)))'
Write-Host "Name '"$group.name"', add count '"$Memers.count"'"
if ($Memers.count -ne 0) {
    Add-ADGroupMember -Identity $group -Members $Memers
}

# Скрипт удаления пользователей из группы LG-Transport в случае присутствия в ней сотрудников департамента 726/087

$OU = "OU=087,OU=726,OU=Пользователи,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
$GR = "CN=LG-Transport,OU=LG,OU=JIRA,OU=Безопасность,OU=Группы,OU=Ижмаш,OU=Concern Kalashnikov,DC=npo,DC=izhmash"

$group = Get-ADGroup -Identity $GR
[array]$userOutGroup = Get-ADUser -SearchBase $OU –LDAPFilter "(memberOf=$($group.DistinguishedName))"
Write-Host "Name '"$group.name"', add count '"$userOutGroup.count"'"
if ($userOutGroup.count -ne 0) {
    Remove-ADGroupMember -Identity $group -Members $userOutGroup -Confirm:$false
}