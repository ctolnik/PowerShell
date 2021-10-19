
import-module activedirectory
(Get-Host).UI.RawUI.ForegroundColor = "Green"
CLEAR
$TimeStamp = (get-date).ToShortDateString()


#Создать соответствующие папки/файлы
$PathCreatedContact = "\\ZZZ\000\system\1C-AD\AD\LOGS\CreatedContact-" + $TimeStamp + ".txt" #chpath
$PathCreateError = "\\ZZZ\000\system\1C-AD\AD\LOGS\CreateError-" + $TimeStamp + ".txt" #chpath
$PathNewOU = "\\ZZZ\000\system\1C-AD\AD\LOGS\NewOU-" + $TimeStamp + ".txt" #chpath
$PathMove = "\\ZZZ\000\system\1C-AD\AD\LOGS\move-" + $TimeStamp + ".txt" #chpath

$today = get-date -Format "yyyyMMdd"

# Функция - правила транслетирации имён
Function Transliteral ([String]$InStr) {
        $ConvRules = @{"а" = "a"; "б" = "b"; "в" = "v"; "г" = "g"; "д" = "d"; "е" = "e"; "ё" = "e"; "ж" = "zh"; "з" = "z"; "и" = "i"; "й" = "y"; "к" = "k"; "л" = "l"; "м" = "m"; "н" = "n"; "о" = "o"; "п" = "p"; "р" = "r"; "с" = "s"; "т" = "t"; "у" = "u"; "ф" = "f"; "х" = "h"; "ц" = "c"; "ч" = "ch"; "ш" = "sh"; "щ" = "sch"; "ъ" = ""; "ы" = "y"; "ь" = ""; "э" = "e"; "ю" = "u"; "я" = "ya" };

        $s = $InStr

        for ($i = 0; $i -le $s.Length - 1; $i++) {
                $ch = $ConvRules[$s[$i].ToString().ToLower()]
                if ( $s[$i].ToString().ToUpper() -ceq $s[$i].ToString() ) { $ch = $ch.Replace($ch[0], $ch[0].ToString().ToUpper()); }
                $trn = $trn + $ch;
        }
        $trn
}


# Функция Получаем логин по полному имени 
Function get-login ([string]$displayname) {
        $lastname = $displayname.Substring(0, $displayname.indexof(" "))
        $name = $displayname.Substring($displayname.indexof(" "))
        $name = $name.Substring(1)
        $name = $name.Substring(0, $name.indexof(" "))
        $fname = $displayname.Substring($displayname.indexof(" "))
        $fname = $fname.Substring($fname.LastIndexOf(" "))
        $fname = $fname.Substring(1)
        $tname = Transliteral -InStr $name
        $tlastname = Transliteral -InStr $lastname
        $tfname = Transliteral -InStr $fname
        $aduserexist = $true
        $i = 1
        while ($aduserexist -eq $true) {
                $testuserexist = $null
                $aduser_test = $prefix + $tname.Substring(0, $i) + "." + $tfname.Substring(0, 1) + "." + $tlastname
                $testuserexist = Get-ADUser -filter { sAMAccountName -eq $aduser_test } -ErrorAction SilentlyContinue
                if (!$testuserexist) {
                        $login = $prefix + $tname.Substring(0, $i) + "." + $tfname.Substring(0, 1) + "." + $tlastname
                        $aduserexist = $false
                }
                Else {
                        $i++
                }
        }
        $login.ToLower()    
}

#определяем кодировку файла
function Get-FileEncoding {
        [CmdletBinding()] Param (
                [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string]$Path
        )

        [byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path

        if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
        { Write-Output 'UTF8' }
        elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
        { Write-Output 'Unicode' }
        elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
        { Write-Output 'UTF32' }
        elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76)
        { Write-Output 'UTF7' }
        else
        { Write-Output 'ASCII' }
}


# редактируем строку
function truncate64 ($String) {
        if ($String.length -gt 64) {
                $String = $String.Substring(0, 64)
                $Stringar = $String -split "\s"
                $String = $null
                for ($i = 0; $i -lt $Stringar.Length - 1; $i++) {
                        $String = $String + $Stringar[$i] + " "
                }
                $String = $String.Substring(0, $String.Length - 1)
        }
        return $String
}

$dc = (Get-ADDomainController -Discover -ForceDiscover).IPv4Address

echo "Подключаемся к контроллеру домена $dc"


#Функция отправки письма

function showresult($tableForMessage1, $Create1, $exist1, $createerror1, $move1, $startTime1, $endTime1) {
        echo "Время начала обновления: $startTime1"
        echo "Обработано контактов: $exist1"
        echo "Создано новых контактов: $Create1"
        echo "Перемещено существующих контактов: $move1"
        echo "Ошибки при создании контактов: $createerror1"
        echo "Время окончания обновления: $endTime1"

        $Server = "mail.000rrr.ru" # SMTP Сервер
        $From = "it@000rrr.ru" # Адрес отправителя
        $To = @" # Получатель
        $Subject = "rrr Принятые сотрудники" # Тема сообщения
        $Body = "<table><tr><td>Время начала обновления: $startTime1 </tr></td>
<tr><td>Обработано контактов: $exist1 </tr></td>
<tr><td>Создано новых контактов: $Create1 </tr></td>
<tr><td>Перемещено существующих контактов: $move1 </tr></td>
<tr><td>Ошибки при создании контактов: $createerror1 </tr></td>
<tr><td>Время окончания обновления: $endTime1 </tr></td>
</table>"

        $Body = $Body + $tableForMessage1

        $SmtpClient = New-Object System.Net.Mail.SmtpClient
        $Message = New-Object System.Net.Mail.MailMessage
        $SmtpClient.Host = $Server
        $Message.IsBodyHtml = $true
        $Message.From = $From
        $Message.To.Add($To)
        $Message.Subject = $Subject
        $Message.Body = $Body | Format-List | Out-String

        if (Test-Path "$PathNewOU") {
                $file = "$PathNewOU"
                $att = new-object Net.Mail.Attachment($file)
                $Message.Attachments.Add($att)
        }

        if (Test-Path "$PathCreateError") {
                $file = "$PathCreateError"
                $att = new-object Net.Mail.Attachment($file)
                $Message.Attachments.Add($att)
        }

        if (Test-Path "$PathMove") {
                $file = "$PathMove"
                $att = new-object Net.Mail.Attachment($file)
                $Message.Attachments.Add($att)
        }


        if (Test-Path "$PathCreatedContact") {
                $file = "$PathCreatedContact"
                $att = new-object Net.Mail.Attachment($file)
                $Message.Attachments.Add($att)
        }


        $SmtpClient.Send($Message)

}


$tableForMessage = "<table><tr><td>ФИО</td><td>Должность</td><td>Подразделение</td><td>Расположение</td></tr>"

#Создать папки
$SuccessPath = "\\ZZZ\000\system\1C-AD\AD\SUCCESS\" #chpath

$startTime = (get-date).ToString()

$filterName = $today + "*_new.csv"

#получаем все файлы по фильтру
$Files = Get-Item \\ZZZ\000\system\1C-AD\* -Include $filterName

#Получаем всех пользваотелей AD
$existUser = Get-ADUser -Filter * -Properties ObjectGUID, distinguishedName, EmployeeNumber -server $dc

foreach ($GetFile in $Files) {
        $Filename = "\\ZZZ\000\system\1C-AD\" + $GetFile.name  #chpath
        $FileEncode = Get-FileEncoding $Filename

        if ($FileEncode -notlike "UTF8") {
                $FileContent = Get-Content $Filename
                $FileContent |  Out-File -FilePath $Filename -Encoding UTF8
        }

        if ($FileEncode -like "UTF8") {

                $SuccessFile = $SuccessPath + $GetFile.name

                if (!(Test-Path "$SuccessFile")) {

                        $File = Import-CSV $FileName -Delimiter ";"

                        $exist = 0
                        $Create = 0
                        $createerror = 0
                        $move = 0

                        $i = 0


                        $failcreated = 0 # контроль ошибок
                        $erlogin = "" # сбойный логин

                        $File | foreach-object {
                                $org = $_.IBLOCK_SECTION_NAME_1
                                $Name1 = $_.IBLOCK_SECTION_NAME_2
                                $Name2 = $_.IBLOCK_SECTION_NAME_3
                                $Name3 = $_.IBLOCK_SECTION_NAME_4
                                $Name4 = $_.IBLOCK_SECTION_NAME_5
                                $Name5 = $_.IBLOCK_SECTION_NAME_6
                                $Name6 = $_.IBLOCK_SECTION_NAME_7
                                $Code1 = $_.IBLOCK_SECTION_CODE_2
                                $Code2 = $_.IBLOCK_SECTION_CODE_3
                                $Code3 = $_.IBLOCK_SECTION_CODE_4
                                $Code4 = $_.IBLOCK_SECTION_CODE_5
                                $Code5 = $_.IBLOCK_SECTION_CODE_6
                                $Code6 = $_.IBLOCK_SECTION_CODE_7

                                #Progress Bar
                                #$i++
                                #$proc = $i / $file.count*100
                                #$proc1 = '{0:F}' -f $proc
                                #Write-Progress -Activity "Update Active Directory $proc1 %" -status "User $fullname" -percentComplete $proc

                                $fullname = $_.LAST_NAME + " " + $_.NAME + " " + $_.SECOND_NAME
                                $sNum = $_.SSN


                                #Проверяем содержит ли СНИЛС цифры. Если нет, то не обрабатываем
                                if ($sNum -match "\d") {

                                        $tn = $_.TN
                                        $countFile = 0

                                        #Ищем однофамильцев в Файле

                                        foreach ($one in $File) {
                                                $fullnamefromFile = $one.LAST_NAME + " " + $one.NAME + " " + $one.SECOND_NAME
                                                if ($fullnamefromFile -like $fullname) {
                                                        $countFile = $countFile + 1
                                                }
                                        }


                                        $count = 0


                                        #Признак существования данного пользователя
                                        $thisexist = 0


                                        #$existUser = $null
                                        $uvolUser = $null

                                        echo "Проверяем существует ли однофамильцы либо уже созданный пользователь или контакт у $fullname с номером $sNum"
     
                                        if ($existUser.EmployeeNumber -contains $sNum) {
                                                $GetexistUserSnum = Get-ADUser -Filter 'employeeNumber -like $sNum' -Properties ObjectGUID, distinguishedName, EmployeeNumber -server $dc
                                                foreach ($GetexistUser in $GetexistUserSnum) {
                                                        echo "Пользователь существует"
                                                        $thisexist = 1
                    
                                                        if ($GetexistUser.ObjectClass -like "contact" -and $GetexistUser.distinguishedName -notlike "*Конвертированные*") {
                                                                echo "Найден контакт!"
                                                                $thiscontact = 1
                                                        }
                                                        if ($GetexistUser.ObjectClass -like "user") {
                                                                echo "Найден пользователь"
                                                                $thiscontact = 0
                                                                $notuvolUser = $GetexistUser
                                                        }

                                                        if ($GetexistUser.distinguishedName -like "*OU=Пользователи,OU=000,OU=Уволенные,DC=npo,DC=izhmash") {
                                                                echo "Пользователь был ранее уволен. Принимаем снова и переводим в новое подразделение"
                                                                $thisexist = 2
                                                                $uvolUser = $GetexistUser
                                                        }
                                                }              
                                        }


                                        #готовим данные для внесения в АД

                                        if ($_.IBLOCK_SECTION_NAME_2 -like $_.IBLOCK_SECTION_NAME_3) {
                                                $Name2 = $null
                                        }
                                        if ($_.IBLOCK_SECTION_NAME_3 -like $_.IBLOCK_SECTION_NAME_4) {
                                                $Name3 = $null
                                        }
                                        if ($_.IBLOCK_SECTION_NAME_4 -like $_.IBLOCK_SECTION_NAME_5) {
                                                $Name4 = $null
                                        }
                                        if ($_.IBLOCK_SECTION_NAME_5 -like $_.IBLOCK_SECTION_NAME_6) {
                                                $Name5 = $null
                                        }
                                        if ($_.IBLOCK_SECTION_NAME_6 -like $_.IBLOCK_SECTION_NAME_7) {
                                                $Name6 = $null
                                        }

                                        #Присваеваем значения имени, должности, табельного номера, подразделения
                                        $name = $_.NAME
                                        $sirname = $_.LAST_NAME
                                        $tn = $_.TN
                                        $title = $_.WORK_POSITION
                                        $title = $title.ToLower()
                                        $title = ($Title.Substring(0, 1)).ToUpper() + $Title.Substring(1)
                                        $title = truncate64($title)
                                        $Department = truncate64($Name1)

                                        if ($Name2 -notlike $null -and $Name2 -notlike " ") {
                                                $Department = truncate64($Name2)
                                        }

                                        if ($Name3 -notlike $null -and $Name3 -notlike " ") {
                                                $Department = truncate64($Name3)
                                        }

                                        if ($Name4 -notlike $null -and $Name4 -notlike " ") {
                                                $Department = truncate64($Name4)
                                        }

                                        $root = "OU=000,OU=Domain Computers,DC=npo,DC=izhmash"
                                        echo $root
    
                                        #Формируем путь расположения OU для компьютеров

                                        if ($Name1 -notlike $null -and $Name1 -notlike " ") {

                                                $Script:OUExist = $True
                                                $NewOU = "OU=" + $Code1 + "," + $root #Для компьютеров новая OU
                                                trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
                                                if (!$Script:OUExist) {
        
                                                        NEW-ADOrganizationalUnit $Code1 -Description $Name1 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc 
                                                        echo $Name1
                                                        echo $NewOU >> $PathNewOU
                                                }
           
                                                $root = "OU=" + $Code1 + "," + $root
                                                echo $root
                                        }
                                        if ($Name2 -notlike $null -and $Name2 -notlike " ") {

                                                $Script:OUExist = $True
                                                $NewOU = "OU=" + $Code2 + "," + $root
                                                trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU  -Server $dc | Out-Null
                                                if (!$Script:OUExist) {
                                                        NEW-ADOrganizationalUnit $Code2 -Description $Name2 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc 
                                                        echo $Name2
                                                        echo $NewOU >> $PathNewOU
                                                }
           
                                                $root = "OU=" + $Code2 + "," + $root
                                                echo $root
                                        }
                                        if ($Name3 -notlike $null -and $Name3 -notlike " ") {

                                                $Script:OUExist = $True
                                                $NewOU = "OU=" + $Code3 + "," + $root
                                                trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU  -Server $dc | Out-Null
                                                if (!$Script:OUExist) {
                                                        NEW-ADOrganizationalUnit $Code3 -Description $Name3 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc 
                                                        echo $Code3
                                                        echo $NewOU >> $PathNewOU
                                                }
           
                                                $root = "OU=" + $Code3 + "," + $root
                                                echo $root

                                        }


                                        $root = "OU=Пользователи,OU=rrr,OU=Concern Kalashnikov,DC=npo,DC=izhmash"
                                        echo $root
           
                                        #Формируем путь расположения контакта. Если пути нет, то создаем структуру подразделений для этого контакта
    
                                        if ($Name1 -notlike $null -and $Name1 -notlike " ") {

                                                $Script:OUExist = $True
                                                $NewOU = "OU=" + $Code1 + "," + $root #Для компьютеров новая OU
                                                trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
                                                if (!$Script:OUExist) {
        
                                                        NEW-ADOrganizationalUnit $Code1 -Description $Name1 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc 
                                                        echo $Name1
                                                        echo $NewOU >> $PathNewOU
                                                }
          
        
                                                echo $root
                                                $root = "OU=" + $Code1 + "," + $root
                                                echo $root
                                        }
                                        if ($Name2 -notlike $null -and $Name2 -notlike " ") {

                                                $Script:OUExist = $True
                                                $NewOU = "OU=" + $Code2 + "," + $root
                                                trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU  -Server $dc | Out-Null
                                                if (!$Script:OUExist) {
                                                        NEW-ADOrganizationalUnit $Code2 -Description $Name2 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc 
                                                        echo $Name2
                                                        echo $NewOU >> $PathNewOU
                                                }
          
                                                $root = "OU=" + $Code2 + "," + $root
                                                echo $root
                                        }
                                        if ($Name3 -notlike $null -and $Name3 -notlike " ") {

                                                $Script:OUExist = $True
                                                $NewOU = "OU=" + $Code3 + "," + $root
                                                trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU  -Server $dc | Out-Null
                                                if (!$Script:OUExist) {
                                                        NEW-ADOrganizationalUnit $Code3 -Description $Name3 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc 
                                                        echo $Code3
                                                        echo $NewOU >> $PathNewOU
                                                }
         
                                                $root = "OU=" + $Code3 + "," + $root
                                                echo $root

                                        }


                                        #Если есть однофамильцы, то создаем контакт с табельным номером
                                        if ($count -gt 0 -or $countFile -gt 1) {
                                                #Если данный пользователь не существует, то создаем контакт
                                                if ($thisexist -eq 0) {
                                                        echo "Создаем контакт...."
                                                        $disname = $fullname
                                                        $fullname = $fullname + " " + $tn
                    (Get-Host).UI.RawUI.ForegroundColor = "Green"
                                                        echo "Создаем контакт для $fullname в $root"
                    (Get-Host).UI.RawUI.ForegroundColor = "Green"
                                                        $login = get-login $fullname
                                                        $upn = $login + "@000rrr.ru"
                                                        $manager = $null
                                                        if ($File.CHIEF_SSN -ne $null) {
                                                                $CHIEFSSN = $File.CHIEF_SSN
                                                                $manager = Get-ADuser -Filter 'employeeNumber -like $CHIEFSSN'
                                  
                                                        }
                                                        #New-ADObject -name $fullname -type contact -path $root -DisplayName $disname -OtherAttributes @{'givenname'="$name";'sn'="$sirname";'title'="$title";'Department'="$Department";'employeeNumber'="$sNum";'description'="$tn"} -ProtectedFromAccidentalDeletion $false -Server $dc
                                                        New-ADUser -Name $fullname -Path $root -DisplayName $fullname -OtherAttributes @{'givenname' = "$name"; 'sn' = "$sirname"; 'title' = "$title"; 'Department' = "$Department"; 'employeeNumber' = "$sNum"; 'description' = "$tn" } $false -Server $dc -SamAccountName $login -PasswordNotRequired $True -UserPrincipalName $upn -Company $org -Manager $manager
                                                        if ($? -eq $False) {
                                                                echo $fullname
                                                                echo $fullname >> $PathCreateError
                                                                echo $root >> $PathCreateError
                                                                echo $error[0] >> $PathCreateError
                                                                echo $thisexist >> $PathCreateError
                                                                echo $tn >> $PathCreateError
                                                                $createerror = $createerror + 1
                                                        }
                                                        else {
                                                                $tableForMessage = $tableForMessage + "<tr><td>" + $fullname + "</td><td>" + $title + "</td><td>" + $department + "</td><td>" + $root + "</td></tr>"
                                                                echo "$fullname;$title;$department" >> $PathCreatedContact
                                                                $Create = $Create + 1
                                                        }  
                                                }        
                                        }

                                        echo $root
                                        #Если однофамильцев нет, то создаем контакт
                                        if ($countFile -eq 1 -and $count -eq 0) {
    
                                                #Если данный пользователь не существует, то создаем контакт
                                                if ($thisexist -eq 0) {
                                                        echo "Создаем контакт...."
                    (Get-Host).UI.RawUI.ForegroundColor = "Green"
                                                        echo "Создаем контакт для $fullname в $root"
                    (Get-Host).UI.RawUI.ForegroundColor = "Green"
                                                        $login = get-login $fullname
                                                        $upn = $login + "@000rrr.ru"
                                                        $manager = $null
                                                        if ($File.CHIEF_SSN -ne $null) {
                                                                $CHIEFSSN = $File.CHIEF_SSN
                                                                $manager = Get-ADuser -Filter 'employeeNumber -like $CHIEFSSN'
                                                        }
                                                        New-ADUser -Name $fullname -Path $root -DisplayName $fullname -OtherAttributes @{'givenname' = "$name"; 'sn' = "$sirname"; 'title' = "$title"; 'Department' = "$Department"; 'employeeNumber' = "$sNum"; 'description' = "$tn" } -Server $dc -SamAccountName $login -PasswordNotRequired $True -UserPrincipalName $upn -Company $org -Manager $manager
                                                        if ($? -eq $False) {
                                                                echo $fullname
                                                                echo $fullname >> $PathCreateError
                                                                echo $root >> $PathCreateError
                                                                echo $error[0] >> $PathCreateError
                                                                echo $thisexist >> $PathCreateError
                                                                echo $tn >> $PathCreateError
                                                                $createerror = $createerror + 1
                           
                                                        }
                                                        else {
                                                                $tableForMessage = $tableForMessage + "<tr><td>" + $fullname + "</td><td>" + $title + "</td><td>" + $department + "</td><td>" + $root + "</td></tr>"
                                                                echo "$fullname;$title;$department" >> $PathCreatedContact
                                                                $Create = $Create + 1
                                                        }
                                                }                      
                                        }
                                        #Если сотрудник числиться в уволенных, то перемещаем его
                                        echo $root
                                        if ($thisexist -eq 2) {
                                                $move = $move + 1
                                                echo "Перемещаем контакт $fullname в $root"
                                                Set-ADObject $uvolUser.ObjectGUID -Replace @{'DisplayName' = "$fullname"; 'givenName' = "$name"; 'sn' = "$sirname"; 'title' = "$title"; 'Department' = "$Department"; 'description' = "$tn"; 'EmployeeNumber' = "$sNum" }  -Server $dc
                                                Move-ADObject $uvolUser.ObjectGUID -TargetPath $root  -Server $dc
                                                Enable-ADAccount $uvolUser.ObjectGUID -Server $dc
                                                $username = $uvolUser.name
                                                echo $uvolUser >> $PathMove
                                                $tableForMessage = $tableForMessage + "<tr><td>" + $username + "</td><td></td><td></td><td>" + $root + "</td></tr>"
                                                echo "Переведена в $root" >> $PathMove
                                        }

                                        if (($thisexist -eq 1) -and ($thiscontact -eq 0)) {
                                                $move = $move + 1
                                                echo "Перемещаем контакт $fullname в $root"
                                                Set-ADObject $notuvolUser.ObjectGUID -Replace @{'DisplayName' = "$fullname"; 'givenName' = "$name"; 'sn' = "$sirname"; 'title' = "$title"; 'Department' = "$Department"; 'description' = "$tn"; 'EmployeeNumber' = "$sNum" }  -Server $dc
                                                Move-ADObject $notuvolUser.ObjectGUID -TargetPath $root  -Server $dc
                                                Enable-ADAccount $notuvolUser.ObjectGUID -Server $dc
                                                $username = $notuvolUser.name
                                                echo $notuvolUser >> $PathMove
                                                $tableForMessage = $tableForMessage + "<tr><td>" + $username + "</td><td></td><td></td><td>" + $root + "</td></tr>"
                                                echo "Переведена в $root" >> $PathMove
                                        }


                                        $exist = $exist + 1

                                        # 2020-12-24 Asker -> Надо переписать этот блок. некорректно отрабатывает репорт
                                        echo "Login is $login"
                                        if (!$login) {
                                                $UserCreated = Get-ADUser -Identity $login -server $dc
                                                if ($UserCreated.count -eq 0) {
                                                        $failcreated++
                                                        $erlogin += [System.Environment]::NewLine + $login
                                                }
                                                else {
                                                        echo "Login is NULL"
                                                }
                                        }
                
        
                                } # Конец - > Проверяем содержит ли СНИЛС цифры. Если нет, то не обрабатываем
                                else {
                                        echo "Для сотрудника $fullname указан не корректный СНИЛС $sNum"
                                        echo "Для сотрудника $fullname указан не корректный СНИЛС $sNum">>$PathCreateError
                                }

                        } # Конец -> foreach-object



                        $tableForMessage = $tableForMessage + "</table>"

                        # 2020-12-24 Asker -> Надо переписать этот блок. некорректно отрабатывает репорт
                        if ($failcreated -eq 0) {
                                Copy-Item $Filename $SuccessPath

                                $endTime = (get-date).ToString()

                                showresult $tableForMessage $Create $exist $createerror $move $startTime $endTime
                        }

                        if ($failcreated -eq 1) {

                                $endTime = (get-date).ToString()
                                $mess = "ВОЗНИКЛА ОШИБКА ПРИ СОЗДАНИИ ПОЛЬЗОВАТАЛЕЙ \n" + $erlogin
                                showresult  $mess $Create $exist $createerror $move $startTime $endTime
                        }

                }            
        }

} 
