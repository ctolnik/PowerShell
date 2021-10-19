#########ОТКРЫТИЕ СЕССИИ С EXCHANGE############################################################
$s = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://mh/PowerShell/ -Authentication Kerberos
Import-PSSession $s
#########ВЫГРУЗКА ПОЛЬЗОВАТЕЛЕЙ############################################################
$OuMMZ = ""
$OuExt = ""

$UsersMMZ = Get-ADUser -SearchBase $OuMMZ -Filter *  -Properties mail, distinguishedName 
$UsersExt = Get-ADUser -SearchBase $OuExt -Filter *  -Properties mail, distinguishedName 

$adusers = $UsersMMZ +  $UsersExt 
$groupmembers = Get-adgroup all-mmz –properties Member | select –expandproperty Member
#########ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЕЙ В ГРУППУ############################################################
foreach ($aduser in $adusers)
{
    $ismember = $false
    if ($aduser.mail -ne $null)
    {
        foreach ($groupmember in $groupmembers)
        {
            if ($aduser.distinguishedName -eq $groupmember)
            {
                $ismember = $true
            }
        }
    }
    if ($ismember -eq $false)
    {
        Add-ADGroupMember -Identity all-mmz -Members $aduser
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
#        Remove-ADGroupMember -Identity all-mmz -Members $groupmember -Confirm:$false
#    }
#}