# Скрипт для обновления кадровой информации в AD на основании выгрузок из 1С
## Импорт модулей
import-module activedirectory

## Объявление переменных
$timestamp = (get-date).ToShortDateString()
$PathUvol = "\\ZZZ\system$\1C-AD\000\1C-AD\AD\LOGS\uvol-" + $TimeStamp + ".txt" # Логируем уволенных в этот файл
$today = get-date -Format "yyyyMMdd" # сегодня
$dc = (Get-ADDomainController -Discover -ForceDiscover).IPv4Address # Находим DC в домене
$startTime = (get-date).adddays(-1).ToString() # дата - вчера
#$deleted_today = $today + "*_deleted.csv" # фильтр "сегодня" *_deleted.csv 
$files_w_deleted = Get-Item \\ZZZ\system$\1C-AD\000\1C-AD\* -Include 


# Выбираем файлы по фильтру "сегодня" *_deleted.csv

$successPath = "\\ZZZ\system$\1C-AD\000\1C-AD\AD\SUCCESS\" # Путь к папке в которую копируют обработанные файлы (ниже $filename)

$PathCreatedContact = "\\ZZZ\system$\1C-AD\000\1C-AD\AD\LOGS\CreatedContact-" + $TimeStamp + ".txt" #chpath
$PathCreateError = "\\ZZZ\system$\1C-AD\000\1C-AD\AD\LOGS\CreateError-" + $TimeStamp + ".txt" #chpath
$PathNewOU = "\\ZZZ\system$\1C-AD\000\1C-AD\AD\LOGS\NewOU-" + $TimeStamp + ".txt" #chpath
$PathMove = "\\ZZZ\system$\1C-AD\000\1C-AD\AD\LOGS\move-" + $TimeStamp + ".txt" #chpath

# Переменные из полезной нагрузки






## Объявление функций
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


	$Server = "mail.000*.ru" # SMTP Сервер
	$From = "it@000*.ru" # Адрес отправителя
	$To = "*ov@000*.ru" # Получатель
	$Subject = "xxx Уволенные сотрудники" # Тема сообщения
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


# Проверка файла



foreach ($GetFile in $Files) { # берем файлы по фильтру по заданному пути
    
	$Filename = "\\ZZZ\system$\1C-AD\000\1C-AD\" + $GetFile.name # Берем имя текущего файла в цикле

	$FileEncode = Get-FileEncoding $Filename #Определяем тип кодировки файла

	if ($FileEncode -notlike "UTF8") { # Если не UFT8 то считываем и сохраняем в UFT8
		$FileContent = Get-Content $Filename
		$FileContent |  Out-File -FilePath $Filename -Encoding UTF8
	}

	if ($FileEncode -like "UTF8") { # Если UFT8 тогда...

		$SuccessFile = $SuccessPath + $GetFile.name # Формируем путь к файлу в папке SUCCESS

		if (!(Test-Path "$SuccessFile")) { # Если данного файла нет в папке SUCCESS значит его еще не отработали и двигаемся дальше

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
                
				# Читаем входящих участников группы 000-BlockDisable (блокировка от выключения учетки)
				$members = Get-ADGroupMember -Identity "000-BlockDisable" -Recursive | Select -ExpandProperty distinguishedName
				If ($members -contains $user) {
					$ismemberNFB = $true
				}
				Else {
					$ismemberNFB = $false
				}

				if (($user -notlike $null) -and ($ismemberNFB -eq $false)) { # Если юзер не null и не NFB
                    
					# Перемещаем выключенного пользователя в OU уволенных сотрудников
					Move-ADObject $user.ObjectGUID -TargetPath "OU=Пользователи,OU=000,OU=Уволенные,DC=npo,DC=izhmash" -Server $dc 
                    
					echo $user.name >>$PathUvol # пришем в лог имя сотрудника которого выключили и переместили
					$move = $move + 1 # увеличиваем счетчик перемещений
					$tableForMessage = $tableForMessage + "<tr><td>" + $user.name + "</td></tr>" # Добавляем запись в таблицу html отчета
				}
			} # конец foreach-object

			$tableForMessage = $tableForMessage + "</table>" # Добавляем запись в таблицу html отчета

			Copy-Item $Filename $SuccessPath # Копируем отработаный файл в папку SUCCESS

			$endTime = (get-date).ToString() # Время окончания периода

			# Отправляем подготовленный отчет на почту (был выключен)
			showresult $tableForMessage $count $move $startTime $endTime
		}
	}
} # Конец foreach

## Выполнение нагрузки
# 