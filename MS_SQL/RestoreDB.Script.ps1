# Автор: Кокорников Илья
# Назанчение: Восстановление СУБД в AoG для R50
# Условие: Удалить базу и ее файлы, перед тем как ее восстанавливать.
# Полная инструкция по восстановлению на WiKi: http://r*wikiweb01.*.*.

Import-Module SQLPS

### 1. ФУНКЦИИ
## !!!! В данном разделе менять переменные запрещено.

# 1.1 Функция проверки базы

function Check-SqlDatabase($serverName, $databaseName) {
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverName)
    $db = $server.databases[$databaseName]
    if ($db) {
        $true
    }
    else { $false }
}
Y
# 1.2 Функция удаления базы

Function Delete-SqlDatabase($serverName, $databaseName) {    

    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverName)
    $db = $server.databases[$databaseName]
    if ($db) {
        $server.KillAllprocesses($databaseName)
        $db.Drop()
    }
}

# 1.3 Функция проверки реплики

Function Check-SqlReplic ($serverName, $AG, $Base) {    
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverName)
    $server.AvailabilityGroups[$AG].DatabaseReplicaStates | Select-Object AvailabilityReplicaServerName, AvailabilityDatabaseName, SynchronizationState | ? AvailabilityDatabaseName   -EQ $Base
}

# 1.4 Определение  активной ноды
Function Determine-PrimaryNode ($server, $AG) {    
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($server)
    $server.AvailabilityGroups[$AG].PrimaryReplicaServerName;
}
 
# 1.5 Отключение Jobs
Function Disable-jobs ($server, $Base) {    
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($server)
    $qBase = $Base.Replace($Region, "")
    foreach ($jobs in ($server.JobServer.Jobs  | Where-Object { ($_.name -match $qBase) -and ($_.IsEnabled -eq $TRUE) })) {
        $jobs.IsEnabled = $FALSE
        $jobs.Alter()
    }
}

# 1.6 Включение Jobs
Function Enable-jobs ($server, $Base) {    
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($server)
    $qBase = $Base.Replace($Region, "")
    foreach ($jobs in ($server.JobServer.Jobs  | Where-Object { ($_.name -match $qBase) -and ($_.IsEnabled -eq $False) })) {
        $jobs.IsEnabled = $TRUE
        $jobs.Alter()
    }
}

#1.7 Функция выбора файла

Function Get-FileName($initialDirectory) {   
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
    Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.bak)| *.bak”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} 

#1.8 Функция отправки письма

function Send_mail {
    param (
        [Parameter (Mandatory = $true)]
        [string] $to,
        [Parameter (Mandatory = $true)]
        [string] $sub,
        [Parameter (Mandatory = $true)]
        [string] $body,
        [Parameter (Mandatory = $false)]
        [string]$attach = ""
    )
    # Email SMTP server
    $SMTPServer = "smtp.*.ru"
    # Email FROM
    $EmailFrom = "veeambackup-r77@*.ru" 
    # Email TO
    $EmailTo = $to
    # Email subject
    $EmailSubject = $sub

    # Вложение
    If ($attach -ne "") {
        $file = $attach
        $att = new-object Net.Mail.Attachment($file) 
    }

    # Использвоать для генерации нового шифрованного пароля для ящика (uncomment it)#########
    #$Secure = Read-Host -AsSecureString
    #$Encrypted = ConvertFrom-SecureString -SecureString $Secure
    #$Encrypted | Set-Content C:\Scripts\mail_pass.txt
    #########################################################################################
    [string[]]$recipients = $to.Split(',')
    $username = "veeambackup-r77"
    $Secure2 = Get-Content C:\Scripts\mail_pass.txt | ConvertTo-SecureString
    $credential = New-Object System.Management.Automation.PSCredential ($username, $Secure2)
    Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $credential -UseSsl -From "$EmailFrom" -To $recipients -Subject "$EmailSubject" -Body "$body" -BodyAsHtml
}

# Очищаем переменные
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue
Clear-Host
## 2. Запросы информации для восстановления.
# 2.1. Запрос региона.

Write-Host
Write-Host ″Укажите код региона, с заглавной буквы, без ковычек и пробелов, например R77″ -BackgroundColor White -ForegroundColor Red
$Region = Read-Host ″Введите код региона″ 

# Проверка коректности ввода региона
if ($Region -cnotlike 'R*')
{ Write-Host ″Указан невереный код региона или формат ввода некоректен. Попробуйте заново.″ -ForegroundColor Red; Return }

# 2.2. Запрос базы для восстановления

Write-Host
Write-Host ″Выберите номер базы для восстановления″ -BackgroundColor White -ForegroundColor Red
Write-Host
Write-Host   
Write-Host ″1. "$Region"-ASBNU-WORK″ -ForegroundColor Green
Write-Host ″2. "$Region"-ASKU-WORK″ -ForegroundColor Green
Write-Host ″3. "$Region"-ASZUP-WORK″ -ForegroundColor Green
Write-Host ″4. Exit″ -ForegroundColor Green
Write-Host ″5. "$Region"-BASE-WORK″ -ForegroundColor Green
Write-Host
$Base4R = Read-Host ″Выберите номер″
Write-Host
Write-Host ″Укажите полный путь к резервной копии″ -BackgroundColor White -ForegroundColor Red
Write-Host

Switch ($Base4R) {
    1 { $Base = $Region + "-ASBNU-WORK" }
    2 { $Base = $Region + "-ASKU-WORK" }
    3 { $Base = $Region + "-ASZUP-WORK" }
    4 { Write-Host ″Отмена″; return }
    # Строчка для теста скрипта. Необходимо УДАЛИТЬ!!!!
    5 { $Base = $Region + "-BASE-WORK" }
    default { Write-Host ″Неверный выбор, давай заново.″ -ForegroundColor Red }
}

# 2.3. Запрос имени и пути к файлу резервной копии, с которого будет восстанавливаться база
$DPServer = "\\" + $Region + "DPM11\1c_backups\"
$BPath = Get-FileName -initialDirectory $DPServer

# Проверка на то что выбран файл резервной копии
if ([string]::IsNullOrEmpty($BPath)) {
    Write-Host ″Невыбран файл резервной копии для восстановления. Восстановление прервано.″ -ForegroundColor Red; return
}

# 2.4. Запрос уведомления по почте о завершение работы скрипта

Write-Host
Write-Host ″Включить e-mail уведомление о завершение работы скрипта по восстановлению?″ -BackgroundColor White -ForegroundColor Red
Write-Host
Write-Host   
Write-Host ″1. Да. Я хочу получить на почту уведомление о завершение.″ -ForegroundColor Green
Write-Host ″2. Нет. Не надо!″ -ForegroundColor Green
Write-Host ″0. Остановите скрипт. Я передумал.″ -ForegroundColor Green

$MailNotifyReq = Read-Host ″Введите номер выбранного ответа″


Switch ($MailNotifyReq) {
    1 { $MailNotifyReq = $true }
    2 { $MailNotifyReq = $false }
    0 { Write-Host ″Отмена″; return }
    default { Write-Host ″Неверный выбор, давай заново.″ -ForegroundColor Red }
}

if ($MailNotifyReq -eq $true) {
    Write-Host
    Write-Host ″Укажите E-Mail получателя в домене '@*.ru. Адрес написать ДО символа @'. ″ -BackgroundColor White -ForegroundColor Red
    Write-Host
    $Rcpt = Read-Host ″Укажите emai ДО символа '@'″
}
# Проверка коректности ввода региона
if ($Rcpt -like '*@*')
{ Write-Host ″Указан email с '@' формат ввода некоректен. Попробуйте заново.″ -ForegroundColor Red; Return }
if ($Rcpt -like '***')
{ Write-Host ″Указан email с *.ru формат ввода некоректен. Попробуйте заново.″ -ForegroundColor Red; Return }

if ($MailNotifyReq -eq $false) {
    Write-Host
    Write-Host ″Работа скрипта, без уведомления на электронную почту″ -BackgroundColor White -ForegroundColor Red
    Write-Host
}

# 3. Переменные 

$Number = Get-Random -Maximum 1000 -Minimum 100

#  3.1 Путь для  файлой СУБД на диске D:
$DataP = "D:\PRODUCTION\" + $Base + "\" + $Base + ".mdf"

# 3.2 Путь для   транзакционных логов на SSD диск E: . И названия лога в базе.
$LogB = $Base + "_Log"
$LogP = "E:\PRODUCTION\" + $Base + "\" + $Base + ".ldf"

# 3.3. Переменные для перемещения файлов при восстановлении
$RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($Base, $DataP)
$RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($LogB, $LogP)

# 3.4 Имена серверов
$server1 = $Region + "PAC1CDB01"
$server2 = $Region + "PAC1CDB02"

# 3.5 Пути к Instance

$ServerInstanceP = $server1 + "\PRODUCTION"
$ServerInstanceS = $server2 + "\PRODUCTION"
$AG = $Region + "PAC1CAG"

# Пути к AoG для разных нод AvailabilityGroups
$AoGPrimaryPath = "SQLSERVER:\SQL\" + $ServerInstanceP + "\AvailabilityGroups\" + $AG
$AoGSecondaryPath = "SQLSERVER:\SQL\" + $ServerInstanceS + "\AvailabilityGroups\" + $AG

$AoGPrimaryPathF = $AoGPrimaryPath + "\AvailabilityDatabases\"
$AoGSecondaryPathF = $AoGSecondaryPath + "\AvailabilityDatabases\"

$AoGPrimaryPathFD = $AoGPrimaryPathF + $Base
$AoGSecondaryPathFD = $AoGSecondaryPathF + $Base

$AoGPrimaryPathBase = $AoGPrimaryPath + "\AvailabilityDatabases\" + $Base
$AoGSecondaryPathBase = $AoGSecondaryPath + "\AvailabilityDatabases\" + $Base

#Меню с запросом подтверждения

$title = "Запрос подтверждения"
$messageRemAG1 = "Для продолжения восстановления базы " + $base + ", необходимо ее вывести из Always on Group.Вы действительно хотите ВЫВЕСТИ базу " + $base + " из кластера " + $AG + " на сервере " + $server1 + "?"
$messageRemAG2 = "Для продолжения восстановления базы " + $base + ", необходимо ее вывести из Always on Group.Вы действительно хотите ВЫВЕСТИ базу " + $base + " из кластера " + $AG + " на сервере " + $server2 + "?"
$messageRemDB1 = "Для продолжения восстановления базы " + $base + ", необходимо ее удалить на сервере " + $server1 + ".Вы действительно хотите удалить базу " + $base + "?"
$messageRemDB2 = "Для продолжения восстановления базы " + $base + ", необходимо ее удалить на сервере " + $server2 + ".Вы действительно хотите удалить базу " + $base + "?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Да, хочу."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Нет, не хочу."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

# Пути к файлам для создания временных РК в процессе восстановления
$BackupFileB = $DPServer + "\Manual\" + $Base + "\" + $Base + $Number + "Base.bak"
$BackupFileL = $DPServer + "\Manual\" + $Base + "\" + $Base + $Number + "Log.trn"

## Проверка наличие БД на серверах

#На первой ноде
$Server1DB = Check-SqlDatabase $server1 $Base
$Server2DB = Check-SqlDatabase $server2 $Base

# E-Mail variables

if ($MailNotifyReq -eq $true) {
    $style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
    $style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
    $style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
    $style = $style + "TD{border: 1px solid black; padding: 5px; }"
    $style = $style + "< /style>"

    $RcptTo = $Rcpt + "@*.ru"
}

#### 4.Проверки для восстновления БД

# 4.1 Проверка, что активная нода №1. Если нет, то остановка скрипта с указанием команды как сменить реплику на Ноду №1.
$Node1A = Determine-PrimaryNode $server1 $AG
if ($Node1A -eq $ServerInstanceS)
{ Write-Host -ForegroundColor Red "Реплика на "$ServerInstanceS". Смените реплику на "$ServerInstanceP " И перезапустите этот скрипт. Команда для смены реплики Switch-SqlAvailabilityGroup -Path "$AoGPrimaryPath "." ; return }

# 4.2 Отключение job у БД для восстановления.
Write-Host  "Выключаем  jobs для" $Base -BackgroundColor Black -ForegroundColor Yellow
Start-Sleep -s 05 # Пауза на 15 секунд
Disable-jobs $server1 $Base
Disable-jobs $server2 $Base

# 4.3 Вывод БД из AoG

# 4.3.1 При наличии реплики на первой ноде - удаление
#
if (Test-Path $AoGPrimaryPathFD) 
{ $resultRemAG = $host.ui.PromptForChoice($title, $messageRemAG1, $options, 0) }
switch ($resultRemAG) {
    0 {
        Write-Host -ForegroundColor Green "OK! Вывод базы из AoG!";
        Remove-SqlAvailabilityDatabase -Path $AoGPrimaryPathBase
    }
    1 {
        Write-Host -ForegroundColor Red "Нет. Отказ от вывода базы из AoG. Операция восстановления прервана"; exit
    }
}

# 4.3.2 Проверка реплики на второй ноде. При наличии реплики на второй ноде  - удаление

if (Test-Path $AoGSecondaryPathFD) {
    $resultRemAG = $host.ui.PromptForChoice($title, $messageRemAG2, $options, 0);
    Write-Host  $AoGSecondaryPathFD  -BackgroundColor Black -ForegroundColor Yellow 
}

switch ($resultRemAG) {
    0 {
        Write-Host -ForegroundColor Green "OK! Вывод базы из AoG!";
        Remove-SqlAvailabilityDatabase -Path $AoGSecondaryPathBase
    }
    1 {
        Write-Host -ForegroundColor Red "Нет. Отказ от вывода базы из AoG. Операция восстановления прервана"; exit
    }
}
    
# 4.4 Удаление базы с серверов.

# 4.4.1 Удаление базы с сервера 1
if ($Server1DB)
{ $resultRemDB = $host.ui.PromptForChoice($title, $messageRemDB1, $options, 0) }
switch ($resultRemDB) {
    0 {
        Write-Host -ForegroundColor Green "OK! Удаляем с" $server1 "базу" $Base;
        Delete-SqlDatabase $server1 $Base
    }
    1 {
        Write-Host -ForegroundColor Red "Нет. Отказ от удаления базы с серверов. Операция восстановления прервана"; return
    }
}
  
# 4.4.2 Удаление базы с сервера 2

if ($Server2DB)

{ $resultRemDB = $host.ui.PromptForChoice($title, $messageRemDB2, $options, 0) }
switch ($resultRemDB) {
    0 {
        Write-Host -ForegroundColor Green "OK! Удаляем с" $server2 "базу" $Base;
        Delete-SqlDatabase $server2 $Base
    }
    1 {
        Write-Host -ForegroundColor Red "Нет. Отказ от удаления базы с серверов. Операция восстановления прервана"; exit
    }
}
 
#### 5. Восстановление базы 
# 5.1
Write-Host  "Начинаем процесс восстановления на"  $ServerInstanceP  -BackgroundColor Black -ForegroundColor Yellow

Restore-SqlDatabase -ServerInstance $ServerInstanceP -Database $Base -BackupFile $BPath -RelocateFile @($RelocateData, $RelocateLog)
# 5.2
Restore-SqlDatabase -ServerInstance $ServerInstanceS -Database $Base -BackupFile $BPath -RelocateFile @($RelocateData, $RelocateLog) -NoRecovery 
# 5.3
Backup-SqlDatabase -ServerInstance $ServerInstanceP -Database $Base -BackupFile $BackupFileL -BackupAction Log
# 5.4
Restore-SqlDatabase -ServerInstance $ServerInstanceS -Database $Base -BackupFile $BackupFileL  -RestoreAction Log -NoRecovery
# 5.5
Add-SqlAvailabilityDatabase -Path $AoGPrimaryPath -Database  $Base
#5.6
Add-SqlAvailabilityDatabase -Path $AoGSecondaryPath -Database  $Base

# 6. Завершение работы скрипта
# 6.1 Удаляем временные файлы
Write-Host  "Удаляем временный файл бэкапа "$BackupFileL", созданный скриптом"  -BackgroundColor Black -ForegroundColor Yellow
Start-Sleep -s 15 # Пауза на 15 секунд
Remove-Item -Path $BackupFileL 

# 6.2 Включаем jobs
Write-Host  "Включаем  jobs для" $Base -BackgroundColor Black -ForegroundColor Yellow
Start-Sleep -s 15 # Пауза на 15 секунд
Enable-jobs $server1 $Base
Enable-jobs $server2 $Base

# 6.3 Отправка сообщения на почту

$body1 = Check-SqlReplic $server1 $AG $Base
$body2 = Check-SqlReplic $server2 $AG
$bd1 = $body = $body1 + $body2 | ? AvailabilityDatabaseName -EQ $Base
$bd1 = $body1 + $body2 | ConvertTo-Html -Head $style  -Title "Restore complete" | Out-String

# подсветка статуса в полученно таблице html
$bd1 = $bd1 -replace "Synchronized", "<font color=green><b>Synchronized</b></font>"
$bd1 = $bd1 -replace "NotSynchronizing", "<font color=red><b>NotSynchronizing</b></font>"

if ($MailNotifyReq -eq $true) {
    send_mail $RcptTo "Restore complete" $bd1
} 