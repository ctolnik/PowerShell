import-module activedirectory
$TimeStamp = (get-date).ToShortDateString()
$PathUvol = "\\111\22\system\1C-AD\AD\LOGS\uvol-" + $TimeStamp + ".txt" # Логируем уволенных в этот файл
$today = (get-date -Format "yyyyMMdd") - 1 # вчера
$dc = (Get-ADDomainController -Discover -ForceDiscover).IPv4Address # Находим DC в домене


# Функция определяет и возвращает тип кодировки файла (Unicode,UTF8,UTF32,UTF7,ASCII)
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


# Функция отправляет отчет по почте и пишет в лог
function showresult($tableForMessage1, $count1, $move1, $startTime1, $endTime1) {
	echo "Время начала обновления: $startTime1"
	echo "Обработано контактов: $count1"
	echo "Перемещено контактов: $move1"
	echo "Время окончания обновления: $endTime1"

	echo "Время начала обновления: $startTime1" >> $PathUvol
	echo "Обработано контактов: $count1" >> $PathUvol
	echo "Перемещено контактов в уволенные: $move1" >> $PathUvol
	echo "Время окончания обновления: $endTime1" >> $PathUvol


	$Server = "mail.ZZZuuu.ru" # SMTP Сервер
	$From = "it@ZZZuuu.ru" # Адрес отправителя
	$To = "jj@ZZZuuu.ru" # Получатель
	$Subject = "rrr Уволенные сотрудники" # Тема сообщения
	$Body = "<table>
<tr><td>Время начала обновления: $startTime1 </tr></td>
<tr><td>Обработано контактов: $count1 </tr></td>
<tr><td>Перемещено контактов: $move1 </tr></td>
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

	if (Test-Path "$PathUvol") {
		$file = "$PathUvol"
		$att = new-object Net.Mail.Attachment($file)
		$Message.Attachments.Add($att)
	}
	$SmtpClient.Send($Message)
}


$startTime = (get-date).adddays(-1).ToString() # дата - вчера

$filterName = $today.ToString() + "*_deleted.csv" # фильтр "сегодня" *_deleted.csv

$Files = Get-Item \\xxx\ZZZ\system\1C-AD\* -Include $filterName # Выбираем файлы по фильтру "сегодня" *_deleted.csv

$SuccessPath = "\\111\222\system\1C-AD\AD\SUCCESS\" # Путь к папке в которую копируют обработанные файлы (ниже $filename)

foreach ($GetFile in $Files) {
 # берем файлы по фильтру по заданному пути
    
	$Filename = "\\xxx\ZZZ\system\1C-AD\" + $GetFile.name # Берем имя текущего файла в цикле

	$FileEncode = Get-FileEncoding $Filename #Определяем тип кодировки файла

	if ($FileEncode -notlike "UTF8") {
		# Если не UFT8 то считываем и сохраняем в UFT8
		$FileContent = Get-Content $Filename
		$FileContent |  Out-File -FilePath $Filename -Encoding UTF8
	}

	if ($FileEncode -like "UTF8") {
		# Если UFT8 тогда...

		$SuccessFile = $SuccessPath + $GetFile.name # Формируем путь к файлу в папке SUCCESS

		if (!(Test-Path "$SuccessFile")) {
			# Если данного файла нет в папке SUCCESS значит его еще не отработали и двигаемся дальше

			$File = Import-CSV $FileName -Delimiter ";" # импортируем объекты из текущего файла CSV в перменную $File 

			$tableForMessage = "<table><tr><td>ФИО</td></tr>" # Таблица информации в html (для отчета)

			
			$count = 0
			$move = 0
			$File | foreach-object { # Читаем каждое вхождение объекта
			    
				$user = $null # юзер пока null
				$count = $count + 1 # увеличиваем счетчик
				$sNum = $_.SSN # Считываем хешированный СНИЛС ($sNum - ключ связывающий AD с 1C)
				$ismemberNFB = $null # не является мембером NFB (Not For Block)
                
				# Читаем из AD данные пользователя по фильтру employeeNumber (employeeNumber - ключ связывающий AD с 1C)
				$user = Get-ADObject -Filter 'employeeNumber -like $sNum' -Properties ObjectGUID, EmployeeNumber, ObjectClass -SearchBase "OU=Concern Kalashnikov,DC=npo,DC=izhmash" -server $dc
                
				# Читаем входящих участников группы ZZZ-BlockDisable (блокировка от выключения учетки)
				$members = Get-ADGroupMember -Identity "ZZZ-BlockDisable" -Recursive | Select -ExpandProperty distinguishedName
				If ($members -contains $user) {
					$ismemberNFB = $true
				}
				Else {
					$ismemberNFB = $false
				}

				if (($user -notlike $null) -and ($ismemberNFB -eq $false)) {
					# Если юзер не null и не NFB

					#Выключаем пользователя
					Disable-ADAccount $user.ObjectGUID -Server $dc

					# Перемещаем выключенного пользователя в OU уволенных сотрудников
					Move-ADObject $user.ObjectGUID -TargetPath "OU=Пользователи,OU=ZZZ,OU=Уволенные,DC=npo,DC=izhmash" -Server $dc 
					echo $user.name >>$PathUvol # пришем в лог имя сотрудника которого выключили и переместили
					$move = $move + 1 # увеличиваем счетчик перемещений
					$tableForMessage = $tableForMessage + "<tr><td>" + $user.name + "</td></tr>" # Добавляем запись в таблицу html отчета
				}
			} # конец foreach-object

			$tableForMessage = $tableForMessage + "</table>" # Добавляем запись в таблицу html отчета

			Copy-Item $Filename $SuccessPath # Копируем отработаный файл в папку SUCCESS

			$endTime = (get-date).ToString() # Время окончания периода

			# Отправляем подготовленный отчет на почту
			showresult $tableForMessage $count $move $startTime $endTime
		}
	}
} # Конец foreach