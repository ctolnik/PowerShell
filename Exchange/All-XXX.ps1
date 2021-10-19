#########ОТКРЫТИЕ СЕССИИ С EXCHANGE############################################################
$s = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://xxx-srv-ex1.zzz/PowerShell/ -Authentication Kerberos
Import-PSSession $s
#########ВЫГРУЗКА ПОЛЬЗОВАТЕЛЕЙ############################################################
$adusers = Get-ADUser -SearchBase 'OU=Пользователи,OU=xxx,OU=zzz zzz,DC=zzz,DC=zzz' -Filter *  -Properties mail, distinguishedName
$groupmembers = Get-adgroup all-xxx –properties Member | select –expandproperty Member
#########ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЕЙ В ГРУППУ############################################################
foreach ($aduser in $adusers) {
    $ismember = $false
    if ($aduser.mail -ne $null) {
        foreach ($groupmember in $groupmembers) {
            if ($aduser.distinguishedName -eq $groupmember) {
                $ismember = $true
            }
        }
    }
    if ($ismember -eq $false) {
        Add-ADGroupMember -Identity all-xxx -Members $aduser
    }
}

#########УДАЛЕНИЕ ПОЛЬЗОВАТЕЛЕЙ ИЗ ГРУППЫ############################################################
#foreach ($groupmember in $groupmembers)
#{
#    $isstil = $false
#    foreach ($aduser in $adusers)
#    {
#        if ($aduser.mail -eq $groupmember)
#        {
#            $isstil = $true
#        }
#    }
#    if ($isstil -eq $false)
#    {
#        Remove-ADGroupMember -Identity all-xxx -Members $groupmember -Confirm:$false
#    }
#}