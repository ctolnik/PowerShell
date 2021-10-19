# Скрипт Кокорникова И.В. по сбору данных по подключениям с серверов RD GateWay
# Загружаем модули для сопостовления логина к ФИО и подгрузки подразделений
Import-Module activedirectory

# Определяем переменные

$startTime = (Get-Date).Date + (New-TimeSpan -Hours ((Get-Date).Hour - 1))
$endTime = (Get-Date).Date + (New-TimeSpan -Hours ((Get-Date).Hour)) - (New-TimeSpan -Seconds 1)

#$startTime = Get-Date -Year 2020 -Month 4 -Day 21
#$endTime = Get-Date -Year 2020 -Month 4 -Day 28


$Logname = "C:\Scripts\RDGW\Gathering\Report_" + (Get-Date -Format dd.MM.yyyy) + ".csv"
$server1 = "-SRV-RDGW1"
$server2 = "-SRV-RDGW2"

function Get-RDGWEvents ($serverName) {
    $RDGevents = Get-WinEvent -FilterHashtable @{Logname = "Microsoft-Windows-TerminalServices-Gateway/Operational" ; ID = "303", "202", "307"; StartTime = $startTime; EndTime = $endTime } -ComputerName $serverName  
    $eventsar = @()           

    foreach ($event in $RDGevents) {           
        $eventtype = $type = $null           
        switch ($event.ID) {           
            303 { $eventtype = "disconnect" }           
            307 { $eventtype = "disconnect at timeout" }           
            202 { $eventtype = "disconnected by admin" }                     
        } # end of switch               
          
        $eventsar += New-Object -TypeName PSObject -Property @{           
            RDGServerName = $event.MachineName           
            UserName      = $event.Properties[0].Value           
            IpAddress     = [net.ipaddress]$event.Properties[1].Value           
            Resource      = $Event.Properties[3].Value           
            TimeCreated   = $event.TimeCreated           
            Result        = $eventtype           
            Duration      = $event.Properties[6].Value
            DisplayName   = ""
            Division      = ""
        }           
    }  
    return $eventsar
}                    

$result = Get-RDGWEvents $server1
$result += Get-RDGWEvents $server2
$data = $result |  ? Duration -gt 0 | sort UserName, Resource, TimeCreated –Unique

foreach ($getrow in $data) {
    $getrow.TimeCreated = ((Get-Date $getrow.TimeCreated) - (New-TimeSpan -Seconds $getrow.duration))
}

$byUser = $data | group UserName
$listUsers = $byUser.Name #Массив уникальных логинов пользоваталей
$listADUser = @() #Массив для хранения данных полученных из Active Directory по уникальным пользователям

foreach ($getlistUser in $listUsers) {
    #По каждому уникальному пользоватлю запрашиваем AD и пишем данные об уникальных пользователям в массив listADUser

    $aduser = $null
    $aduser = Get-ADUser -identity $getlistUser.Substring(4)
    $OU = $null
    $OU = $aduser.DistinguishedName
    $OU = $OU.substring($ou.indexof(",") + 1)   
    $ADOU = $null
    $ADOU = Get-ADOrganizationalUnit $OU -Properties description
    
    $listADUser += New-Object -TypeName PSObject -Property @{
        login    = $getlistUser
        FIO      = $aduser.Name
        Division = $ADOU.Description
    }  
}


#Функция нормализации продолжительности подключения в формате hh:mm:ss без учета дней
Function NormalizationDuration ([TimeSpan]$Duration) {
    $h = $Duration.Days * 24 + $Duration.Hours
    $m = $Duration.Minutes
    $s = $Duration.Seconds

    if ($h -lt 10) {
        $h = "0" + $h.ToString()
    }
    if ($m -lt 10) {
        $m = "0" + $m.ToString()
    }
    if ($s -lt 10) {
        $s = "0" + $s.ToString()
    }

    $DurationStr = $h.ToString() + ":" + $m.ToString() + ":" + $s.ToString()

    return $DurationStr
}

$arraycount = 0
$array = @()

foreach ($user in $byUser) {
    foreach ($getconnect in $user.Group | sort TimeCreated) {
        $durConnect = New-TimeSpan -Seconds $getconnect.duration
        $durConnectNorm = NormalizationDuration $durConnect
        $DateTimeConnect = $getconnect.TimeCreated
        $DateTimeDisconnect = $getconnect.TimeCreated + $durConnect
        $DateConnect = $DateTimeConnect.Date    
        $Name = $getconnect.UserName
        $ServerName = $getconnect.Resource
        $Result = $getconnect.Result

        foreach ($userAD in $listADUser) { #Обогащаем информацию о ФИО и имени подразделения
            if ($userAD.login -like $user.Name) {
                $DisplayName = $userAD.FIO
                $Department = $userAD.Division
                break
            }
        }

        $RDGServer = $getconnect.RDGServerName

        if ($getconnect.Resource -like '*zzz-srv*')
        { $ServerType = "Сервер удаленного подключения" }
        else
        { $ServerType = "Удаленный рабочий компьютер" }

        $UserConnect = New-Object System.Object
        $UserConnect | Add-Member -type NoteProperty -name Date -Value $DateConnect
        $UserConnect | Add-Member -type NoteProperty -name DateTimeConnect -Value $DateTimeConnect
        $UserConnect | Add-Member -type NoteProperty -name DateTimeDisconnect -Value $DateTimeDisconnect
        $UserConnect | Add-Member -type NoteProperty -name Name -Value $Name
        $UserConnect | Add-Member -type NoteProperty -name ServerType -Value $ServerType
        $UserConnect | Add-Member -type NoteProperty -name ServerName -Value $ServerName
        $UserConnect | Add-Member -type NoteProperty -name Duration -Value $durConnectNorm
        $UserConnect | Add-Member -type NoteProperty -name DisplayName -Value $DisplayName
        $UserConnect | Add-Member -type NoteProperty -name Department -Value $Department
        $UserConnect | Add-Member -type NoteProperty -name RDGServer -Value $RDGServer
        $UserConnect | Add-Member -type NoteProperty -name Result -Value $Result

        if (($arraycount -gt 0) -and ($DateTimeConnect -ge $array[$arraycount - 1].DateTimeConnect) -and ($DateTimeConnect -le $array[$arraycount - 1].DateTimeDisconnect) -and (($DateTimeDisconnect - (New-TimeSpan -Minutes 2)) -le $array[$arraycount - 1].DateTimeDisconnect) -and ($Name -like $array[$arraycount - 1].Name) -and ($ServerName -like $array[$arraycount - 1].ServerName))

        { }
        else {
            $array += $UserConnect
            $arraycount++
        }
    }
}

$array  | Sort-Object -Descending:$false -Property DateTimeDisconnect |  Export-csv $Logname  -nti -Delimiter ";" -Encoding UTF8 -Append
