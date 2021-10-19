#Создание груп рассылок для каждой OU подразделения


# Определяем переменные
$DC = Get-ADDomainController
$OUs = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Пользователи,OU=rrr,OU=zzz,DC=npo,DC=111" -Properties canonicalname, description | sort canonicalname
$AllUsers = "DM-Все пользователи rrr"
$ADAllUsers = Get-ADGroup $AllUsers -Server $DC

#Exclusions add users from external OU

#$GroupEx = Get-ADGroup -identity "DM-539-001-001" -Properties Member | Select-Object -ExpandProperty Member | Get-ADUser -Server $DC
$Scopeex = "OU=001,OU=001,OU=539,OU=Пользователи,OU=333,OU=zzz,DC=npo,DC=111"
$OUex = Get-ADOrganizationalUnit -Filter * -SearchBase $Scopeex -Properties canonicalname, description | sort canonicalname

# Функции
# Переименование некоректной группы
function rename-incgroup($old_name, $new_name) {
    $old_name | Rename-ADObject -NewName $new_name -Server $DC -Verbose
}

$ou = $ous[3]
# Цикл по созданию / обновлению групп
foreach ($OU in $OUs) {
    #
    if ($OU.name -eq "Для тестов") { continue }
    
    $GroupName = "DM-" + $((($OU.canonicalname).replace("npo.111/zzz/rrr/Пользователи/", "")).replace("/", "-"))
    $ou = $ous[0]
    # Общая группа со всех OU
    if ($OU.canonicalname -eq "npo.111/zzz/rrr/Пользователи") {
        $GroupName = $AllUsers
    }
    $OUDescription = $OU.description 
    
    # Переименование группы, при необходимости
    $result = $null
    $result = Get-ADGroup -Filter 'name -like "DM-*"' -SearchBase $OU -SearchScope OneLevel -Server $DC
    if ($result) {
        if ((Get-ADGroup -Filter 'name -like "DM-*"' -SearchBase $OU -SearchScope OneLevel -Server $DC).Name -ne $GroupName) {
            rename-incgroup -old_name $result -new_name $GroupName
        }
    }

    # Определение группы, при необходимости
    $result = $null
    $result = Get-ADGroup -Filter 'samaccountname -like "DM-*"' -SearchBase $OU -SearchScope OneLevel -Server $DC
    if ($result) {
        if ((Get-ADGroup -Filter 'samaccountname -like "DM-*"' -SearchBase $OU -SearchScope OneLevel -Server $DC).samaccountname -ne $GroupName) {
            $result | Set-ADGroup -samaccountname $GroupName -Server $DC -Verbose
        }
    } 

    try {
        $result = Get-ADGroup $GroupName -Server $DC
    }
    catch {
        Write-Host  "Create $GroupName $OUDescription"

        #  Создание группы
        New-ADGroup -Name $GroupName -Path $OU -SamAccountName $GroupName -GroupCategory Security -GroupScope Global -Description $OUDescription -Server $DC
    }
    # Наполнение группы
    $ShadowGroup = (Get-ADGroup $GroupName -Server $DC).DistinguishedName
    
    if ($ShadowGroup -ne $ADAllUsers.DistinguishedName ) {
        Write-Host  "Начинаем работу над группой" $GroupName 
        Get-ADGroup –Identity $GroupName -Server $DC -Properties Member | Select-Object -ExpandProperty Member | Get-ADUser -Server $DC |
        Where-Object { $_.distinguishedName –NotMatch $OU.DistinguishedName } | ForEach-Object { Remove-ADPrincipalGroupMembership -server $DC –Identity $_ –MemberOf $GroupName –Confirm:$false -Verbose }
        Get-ADUser –SearchBase $OU.DistinguishedName –LDAPFilter "(&(description>=0)(description<=9)(!memberOf=$ShadowGroup)(employeenumber=*))" -Server $DC | ForEach-Object { Add-ADPrincipalGroupMembership -Server $DC –Identity $_ –MemberOf $GroupName -Verbose }      
    }
    else
    {

        Write-Host  "АЛЯРМА!!!!  Начинаем работу над группой" $GroupName 
        # Удаляем залётных членов из группы 
        Get-ADGroup –Identity $GroupName -Server $DC -Properties Member | # Получаем список всех членов группы ALL
        Select-Object -ExpandProperty Member | # Выделяем инфу по участникам группы
        Get-ADUser | Where-Object { $_.distinguishedName –NotMatch $OU.DistinguishedName } | # выбираем тех кто не находится в корневой OU rrr для их удаления
        Where-Object { $_.distinguishedName –NotMatch $OUex.DistinguishedName } | # убираем из списка членов внешних OU
        ForEach-Object { Remove-ADPrincipalGroupMembership -server $DC –Identity $_ –MemberOf $GroupName –Confirm:$false -Verbose } # Удаляем гадов
  

   
        # Добавляем в ALL новоприбывших
        $fGroupName = Get-ADGroup –Identity $GroupName -Server $DC 
        # Из OU MMZ
        Get-ADUser –SearchBase $OU.DistinguishedName –Filter { memberOf -ne $fGroupName.DistinguishedName } -Server $DC |
        ForEach-Object { Add-ADPrincipalGroupMembership -Server $DC –Identity $_ –MemberOf $GroupName -Verbose }      
  
        # Из внешних OU
        Get-ADUser –SearchBase $OUex.DistinguishedName –Filter { memberOf -ne $fGroupName.DistinguishedName } -Server $DC |
        ForEach-Object { Add-ADPrincipalGroupMembership -Server $DC –Identity $_ –MemberOf $GroupName -Verbose }      
    }
   
    
    if ((Get-ADGroup $GroupName -properties description -Server $DC).description -ne $OU.description) {
        Write-Host    $GroupName -Description $OU.description -Verbose -Server $DC
        Set-ADGroup $GroupName -Description $OU.description -Verbose -Server $DC
    }

}