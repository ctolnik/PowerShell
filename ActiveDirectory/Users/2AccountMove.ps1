
import-module activedirectory
$TimeStamp = (get-date).ToShortDateString()

$PathNewOU = "\\xxx\ZZZ\system\1C-AD\AD\LOGS\NewOU-" + $TimeStamp + ".txt" # Лог с информацией о новом OU
 
$PathMove = "\\xxx\ZZZ\system\1C-AD\AD\LOGS\move-" + $TimeStamp + ".txt" # Лог с информацией о перемещаемых

$PathCreateError = "\\xxx\ZZZ\system\1C-AD\AD\LOGS\MoveError-" + $TimeStamp + ".txt" # Лог с информацией об ошибках перемещения
 
$PathApsentError = "\\xxx\ZZZ\system\1C-AD\AD\LOGS\ApsentError-" + $TimeStamp + ".txt" # Лог с информацией о посланных (??)

$today = get-date -Format "yyyyMMdd" #дата сегодня
$time = get-date -Format "HHmm" # время

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
function showresult($tableForMessage1, $count1, $move1, $apsent1, $startTime1, $endTime1) {
	echo "Время начала обновления: $startTime1"
	echo "Обработано контактов: $count1"
	echo "Перемещено контактов: $move1"
	echo "Не найдено контактов: $apsent1"
	echo "Время окончания обновления: $endTime1"

	$Server = "mail.ZZZavod.ru" # SMTP Сервер
	$From = "it@ZZZavod.ru" # Адрес отправителя
	$To = "aaa@ZZZavod.ru" # Получатель
	$Subject = "000 Переведенные сотрудники" # Тема сообщения
	$Body = "<table>
<tr><td>Время начала обновления: $startTime1 </tr></td>
<tr><td>Обработано контактов: $count1 </tr></td>
<tr><td>Перемещено контактов: $move1 </tr></td>
<tr><td>Не найдено контактов: $apsent1 </tr></td>
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

	if (Test-Path "$PathMove") {
		$file = "$PathMove"
		$att = new-object Net.Mail.Attachment($file)
		$Message.Attachments.Add($att)
	}

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

	if (Test-Path "$PathApsentError") {
		$file = "$PathApsentError"
		$att = new-object Net.Mail.Attachment($file)
		$Message.Attachments.Add($att)
	}


	$SmtpClient.Send($Message)


}

# Функция обзерает строку ?
function truncate64 ($String) {
	if ($String.length -gt 64) {
		# если строка больше 64
		$String = $String.Substring(0, 64) #извлекаем подстроку с позиции 0 до 64 символа
		$Stringar = $String -split "\s" # делим строку на массив по пробелу
		$String = $null # обнуляем строку
		for ($i = 0; $i -lt $Stringar.Length - 1; $i++) {
			#пробегаем по массиву
			$String = $String + $Stringar[$i] + " " # собираем строку из массива
		}
		$String = $String.Substring(0, $String.Length - 1)
	}
	return $String

}



$startTime = (get-date).ToString()

$tableForMessage = "<table><tr><td>ФИО</td><td>Конечное подразделение</td><td>Добавлен в группы</td></tr>"

$filterName = $today + "*_changed.csv" # фильтр сегодня + *_changed.csv

$Files = Get-Item \\xxx\ZZZ\system\1C-AD\* -Include $filterName | where { $_.name -notlike "*_schedule_changed.csv" } # Берем все файлы по фильтру, кроме *_schedule_changed.csv

$SuccessPath = "\\xxx\ZZZ\system\1C-AD\AD\SUCCESS\" # Путь к папке в которую копируют обработанные файлы (ниже $filename) 

# Цикл по файлам $Files
foreach ($GetFile in $Files) { 

	$Filename = "\\xxx\ZZZ\system\1C-AD\" + $GetFile.name
	$FileEncode = Get-FileEncoding $Filename #Определяем тип кодировки файла

	# Если не UFT8 то считываем и сохраняем в UFT8
	if ($FileEncode -notlike "UTF8") {
		$FileContent = Get-Content $Filename
		$FileContent |  Out-File -FilePath $Filename -Encoding UTF8
	}

	# Если UFT8
	if ($FileEncode -like "UTF8") {

		$SuccessFile = $SuccessPath + $GetFile.name
		echo "Проверка, обрабатывали ли файл $GetFile...."

		# Файл $GetFile не обрабатывали
		if (!(Test-Path "$SuccessFile")) {
			echo "Файл $GetFile не обрабатывали."
			$File = Import-CSV $FileName -Delimiter ";"

			$count = 0
			$move = 0
			$apsent = 0
			$createerror = 0
			$File | foreach-object {

				# Считываем структуру и коды департамента
				$Name1 = $_.IBLOCK_SECTION_NAME_2 # Департамент, дирекция 
				$Name2 = $_.IBLOCK_SECTION_NAME_3 # Бюро, управление
				$Name3 = $_.IBLOCK_SECTION_NAME_4 # Отдел
				$Name4 = $_.IBLOCK_SECTION_NAME_5 # ПодОтдел
				$Name5 = $_.IBLOCK_SECTION_NAME_6 # ПодПодОтдел
				$Name6 = $_.IBLOCK_SECTION_NAME_7 # ПодПодПодОтдел
				$Code1 = $_.IBLOCK_SECTION_CODE_2 #
				$Code2 = $_.IBLOCK_SECTION_CODE_3 #
				$Code3 = $_.IBLOCK_SECTION_CODE_4 #
				$Code4 = $_.IBLOCK_SECTION_CODE_5 #
				$Code5 = $_.IBLOCK_SECTION_CODE_6 #
				$Code6 = $_.IBLOCK_SECTION_CODE_7 #
       

				# Исключаем ошибки заведения департамента сотрудника в структуре 
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

        
				$title = $_.WORK_POSITION # должность
				$title = $title.ToLower()
				$title = ($Title.Substring(0, 1)).ToUpper() + $Title.Substring(1) # Делаем первую букву заглавной
				$title = truncate64($title) # Отсекаем если больше 64

				$fullname = $_.LAST_NAME + " " + $_.NAME + " " + $_.SECOND_NAME # собираем полное имя
				$NewsNum = $_.NEW_SSN # Новый хеш СНИЛС (вдруг была ошибка)
				$name = $_.NAME # имя
				$sirname = $_.LAST_NAME # фамилия
				$Department = $Name1.ToString() # департамент
        

				# оптимизируем структуру для удобства использования
				if ($Name2 -notlike $null -and $Name2 -notlike " ") {
					# если бюро/управление существует
					$Department = $Name2.ToString() # то "департамент" -> IBLOCK_SECTION_NAME_3
				}

				if ($Name3 -notlike $null -and $Name3 -notlike " ") {
					# если "отдел/управление" существует
					$Department = $Name3.ToString() # то "департамент" -> IBLOCK_SECTION_NAME_4
				}

				if ($Name4 -notlike $null -and $Name4 -notlike " ") {
					# если подотдел/подуправление существует
					$Department = $Name4.ToString() # то "департамент" -> IBLOCK_SECTION_NAME_5
				}
        
				# Отсекаем если больше 64
				$Department = truncate64($Department)
	

				#Создаем структуру каталогов и добавляем описание для Компьютеров

				$root = "OU=ZZZ,OU=Domain Computers,DC=npo,DC=izhmash" # корень структуры компьютеров 000
				if ($Name1 -notlike $null -and $Name1 -notlike " ") {

					$Script:OUExist = $True # маркер существования OU пути
					$NewOU = "OU=" + $Code1 + "," + $root # новый путь
					trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null # Ловушка. Проверяем существует ли новый путь 
					if (!$Script:OUExist) {
						# если пути нет, создаем его
						NEW-ADOrganizationalUnit $Code1 -Description $Name1 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc
						echo $Name1
						echo $NewOU >> $PathNewOU # пишем в лог новый путь
					}
		    
					$root = "OU=" + $Code1 + "," + $root # меняем корень OU 
					Set-ADOrganizationalUnit $root -Description $Name1 -Server $dc # добавляем комментарий OU
		

				}
				if ($Name2 -notlike $null -and $Name2 -notlike " ") {

					$Script:OUExist = $True
					$NewOU = "OU=" + $Code2 + "," + $root
					trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
					if (!$Script:OUExist) {
						NEW-ADOrganizationalUnit $Code2 -Description $Name2 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc
						echo $Name2
						echo $NewOU >> $PathNewOU
					}
					$root = "OU=" + $Code2 + "," + $root
					Set-ADOrganizationalUnit $root -Description $Name2 -Server $dc
		    

				}
				if ($Name3 -notlike $null -and $Name3 -notlike " ") {

					$Script:OUExist = $True
					$NewOU = "OU=" + $Code3 + "," + $root
					trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
					if (!$Script:OUExist) {
						NEW-ADOrganizationalUnit $Code3 -Description $Name3 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc
						echo $Code3
						echo $NewOU >> $PathNewOU
					}
					$root = "OU=" + $Code3 + "," + $root
					Set-ADOrganizationalUnit $root 	-Description $Name3 -Server $dc
	   

				}

				#Создаем структуру каталогов и добавляем описание для Пользователей

				$root = "OU=Пользователи,OU=000,OU=Concern Kalashnikov,DC=npo,DC=izhmash" # корень структуры пользователей 000
				if ($Name1 -notlike $null -and $Name1 -notlike " ") {

					$Script:OUExist = $True
					$NewOU = "OU=" + $Code1 + "," + $root
					trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
					if (!$Script:OUExist) {
						NEW-ADOrganizationalUnit $Code1 -Description $Name1 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc
						echo $Name1
						echo $NewOU >> $PathNewOU
					}
					$root = "OU=" + $Code1 + "," + $root
					Set-ADOrganizationalUnit $root -Description $Name1 -Server $dc
		    

				}
				if ($Name2 -notlike $null -and $Name2 -notlike " ") {

					$Script:OUExist = $True
					$NewOU = "OU=" + $Code2 + "," + $root
					trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
					if (!$Script:OUExist) {
						NEW-ADOrganizationalUnit $Code2 -Description $Name2 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc
						echo $Name2
						echo $NewOU >> $PathNewOU
					}
					$root = "OU=" + $Code2 + "," + $root
					$root
					Set-ADOrganizationalUnit $root 	-Description $Name2 -Server $dc
		    

				}
				if ($Name3 -notlike $null -and $Name3 -notlike " ") {

					$Script:OUExist = $True
					$NewOU = "OU=" + $Code3 + "," + $root
					trap { $Script:OUExist = $False ; continue } Get-ADObject $NewOU -Server $dc | Out-Null
					if (!$Script:OUExist) {
						NEW-ADOrganizationalUnit $Code3 -Description $Name3 –path $root -ProtectedFromAccidentalDeletion $true -Server $dc
						echo $Code3
						echo $NewOU >> $PathNewOU
					}
		   
					$root = "OU=" + $Code3 + "," + $root
					Set-ADOrganizationalUnit $root 	-Description $Name3 -Server $dc
		    
				}

				# Новые структуры созданы и/или обновлены, идем дальше

				$user = $null
				$count = $count + 1 #  Счетчик
				$sNum = $_.SSN # СНИЛС
				$tn = $_.TN # Табельный номер
				echo "Ищем сотрудника со СНИЛС $sNum..."
	    
				# пытаемся получить данные пользователя
				$user = Get-ADObject -Filter 'employeeNumber -like $sNum' -Properties ObjectGUID, EmployeeNumber, ObjectClass -SearchBase "OU=Concern Kalashnikov,DC=npo,DC=izhmash" -server $dc

				if ($user -notlike $null) {
					# если пользователь существует
					echo "Найден сотрудник со СНИЛС $sNum"
					echo "Начинаем обработку объекта..."
					if ($user.name -match "\d") { # если в имени есть цифры (т.е. в имени есть табельный номер)
						echo "Объект имеет имя c табельным номером"
						# обновляем данные пользователя
						Set-ADObject $user.ObjectGUID -Replace @{'DisplayName' = "$fullname"; 'givenName' = "$name"; 'sn' = "$sirname"; 'title' = "$title"; 'Department' = "$Department"; 'description' = "$tn"; 'EmployeeNumber' = "$NewsNum" } -Server $dc -ErrorAction Continue
						if ($? -eq $False) {
							# если появилась ошибка пишем в логи
							echo $fullname
							echo "Ошибка при установке свойств объекту"
							echo "Ошибка при установке свойств объекту" >> $PathCreateError
							echo $fullname >> $PathCreateError
							echo $root >> $PathCreateError
							echo $error[0] >> $PathCreateError
							echo $sNum >> $PathCreateError
							$error.clear()
							$createerror = $createerror + 1
						}
						else {
							echo "Обновление данные сотрудника проивезедено успешно!"
						}
                
						# добавляем новый табельный номер к имени
						Rename-ADObject (Get-ADObject $user.ObjectGUID -Server $dc).DistinguishedName -NewName "$fullname $tn" -Server $dc -ErrorAction Continue
						if ($? -eq $False) {
							echo $fullname
							echo "Ошибка при переименовании объекта"
							echo "Ошибка при переименовании объекта" >> $PathCreateError
							echo $fullname >> $PathCreateError
							echo $root >> $PathCreateError
							echo $error[0] >> $PathCreateError
							echo $sNum >> $PathCreateError
							$error.clear()
							$createerror = $createerror + 1
						}
						else {
							echo "Переименование сотрудника проивезедено успешно!"
						}
		
					}
					else { # иначе делаем то же самое но без табельного номера в имени
						echo "Объект имеет имя без табельного номера"
						Set-ADObject $user.ObjectGUID -Replace @{'DisplayName' = "$fullname"; 'givenName' = "$name"; 'sn' = "$sirname"; 'title' = "$title"; 'Department' = "$Department"; 'description' = "$tn"; 'EmployeeNumber' = "$NewsNum" } -Server $dc -ErrorAction Continue
						if ($? -eq $False) {
							echo $fullname
							echo "Ошибка при установке свойств объекту"
							echo "Ошибка при установке свойств объекту" >> $PathCreateError
							echo $fullname >> $PathCreateError
							echo $root >> $PathCreateError
							echo $error[0] >> $PathCreateError
							echo $sNum >> $PathCreateError
							$error.clear()
							$createerror = $createerror + 1
						}
						else {
							echo "Обновление данные сотрудника проивезедено успешно!"
						}

						Rename-ADObject (Get-ADObject $user.ObjectGUID -Server $dc).DistinguishedName -NewName "$fullname" -Server $dc -ErrorAction Continue
						if ($? -eq $False) {
							echo $fullname
							echo "Ошибка при переименовании объекта"
							echo "Ошибка при переименовании объекта" >> $PathCreateError
							echo $fullname >> $PathCreateError
							echo $root >> $PathCreateError
							echo $error[0] >> $PathCreateError
							echo $sNum >> $PathCreateError
							$error.clear()
							$createerror = $createerror + 1
						}
						else {
							echo "Переименование сотрудника проивезеден успешно!"
						}
		
					}

					$moveUser = 0 #Признак, что сотрудник переводится в то же подразделение
					$dn = $user.DistinguishedName
					echo "Текущий DN пользователя: $dn"
        
					echo "root: $root"
        
					if (!$dn.Contains($root)) {
						# если пользователь не состоит по заданному пути
            
						echo "Перемещаем сотрудника $fullname со СНИЛС $sNum в новый отдел" >> $PathMove	
						echo "Текущий DN пользователя: $dn" >> $PathMove	
						echo "root: $root" >> $PathMove
						echo "Перемещаем сотрудника $fullname со СНИЛС $sNum в новый отдел"
						Move-ADObject $user.ObjectGUID -TargetPath $root -Server $dc -ErrorAction Continue
						$moveUser = 1 #Признак, что сотрудник переводится в другое подразделение
					}

					if ($? -eq $False) {
						# пишем в логи информацию о ошибках
						echo $fullname
						echo "Ошибка при перемещении объекта"
						echo "Ошибка при перемещении объекта" >> $PathCreateError				
						echo $fullname >> $PathCreateError
						echo $root >> $PathCreateError
						echo $error[0] >> $PathCreateError
						echo $sNum >> $PathCreateError
						$error.clear()
						$createerror = $createerror + 1
					}
					else {
						# иначе пишем в логи об успехе перемещения
						$move = $move + 1 # увеличиваем счетчик перемещений
						echo "Сотрудник $fullname со СНИЛС $sNum успешно переведен!"
						$username = $user.name
						$message = "$username перемещен в $root"
						$tableForMessage = $tableForMessage + "<tr><td>" + $username + "</td><td>" + $root + "</td>"
						echo $message >> $PathMove	
					}
				}
				else {
					$apsent = $apsent + 1
					echo "Не найден сотрудник со СНИЛС $sNum"
					$message = "Не найден сотрудник $fullname со СНИЛС $sNum. Должность $title. Место работы: $root"
					echo $message >> $PathApsentError
				}
			} # Конец foreach-object


			$tableForMessage = $tableForMessage + "</table>"

			# перемещаем обработанный файл
			Copy-Item $Filename $SuccessPath 

			$endTime = (get-date).ToString()

			# отправляем отчеты, пишем логи
			showresult $tableForMessage $count $move $apsent  $startTime $endTime 

			$tableForMessage = "<table><tr><td>ФИО</td><td>Конечное подразделение</td><td>Добавлен в группы</td></tr>"

		} # Конец # Файл $GetFile не обрабатывали
	} # Конец -> # Если UFT8
}
