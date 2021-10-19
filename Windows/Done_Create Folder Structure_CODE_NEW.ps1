Import-Module NTFSSecurity
Import-Module ActiveDirectory

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


$dc = (Get-ADDomainController -Discover -ForceDiscover).IPv4Address

$today = get-date -Format "yyyyMMdd"

$SuccessPath = "\\zzz\system$\1C-AD\FILE\SUCCESS\"

$startTime = (get-date).ToString()

$filterName = $today + "*_new*"
$filtername2 = $today + "*_changed*"
$Files = Get-Item \\zzz\system$\1C-AD\* -Include $filterName, $filtername2

foreach ($GetFile in $Files) {
	$Filename = "\\zzz\system$\1C-AD\" + $GetFile.name
	$FileEncode = Get-FileEncoding $Filename
	if ($FileEncode -notlike "UTF8") {
		$FileContent = Get-Content $Filename
		$FileContent |  Out-File -FilePath $Filename -Encoding UTF8
	}

	if ($FileEncode -like "UTF8") {
		$SuccessFile = $SuccessPath + $GetFile.name
		if (!(Test-Path "$SuccessFile")) {

			$File = Import-CSV $FileName -Delimiter ";"

			$Path = "C:\Эталон файловой структуры\"
			$NewPath = "C:\Новые элементы файловой структуры\"
			$time = get-date -Format "ddMMyyyyHH"
			$FileNewFolder = "$NewPath" + "newfolders" + $time + ".txt"

			$File | foreach-object {
				$Name1 = $_.IBLOCK_SECTION_NAME_2
				$Name1 = $Name1 -replace "'"
				$DepartmentName = $_.IBLOCK_SECTION_CODE_2
				$GroupDepROL = "FA-" + $DepartmentName + "-RL"
				$FullPath1 = $Path + $Name1 + "\"
				$NewFullPath1 = $NewPath + $Name1 + "\"
				if (!(Test-Path $FullPath1)) {
					New-Item $FullPath1 -ItemType Directory
					echo "Группа $GroupDepROL"
					$sid = Get-ADGroup $GroupDepROL -Server $dc
					Add-NTFSAccess -Path $FullPath1  -Account $sid.sid -AccessRights Read -AppliesTo ThisFolderOnly
					$sid = $null
					echo $FullPath1
					New-Item $NewFullPath1 -ItemType Directory
					echo "Группа $GroupDepROL"
					$sid = Get-ADGroup $GroupDepROL -Server $dc
					Add-NTFSAccess -Path $NewFullPath1  -Account $sid.sid -AccessRights Read -AppliesTo ThisFolderOnly
					$sid = $null
					echo $NewFullPath1 >> $FileNewFolder
				}


				$GroupDepROL = "FA-" + "TeamWorkDocs-RL"
				$UW = "Совместная работа"
				$FullPathUW = $Path + $UW + "\"
				$NewFullPathUW = $NewPath + $UW + "\"
				if (!(Test-Path $FullPathUW)) {
					New-Item $FullPathUW -ItemType Directory
					echo "Группа $GroupDepROL"
					$sid = Get-ADGroup $GroupDepROL -Server $dc
					Add-NTFSAccess -Path $FullPathUW  -Account $sid.sid -AccessRights Read -AppliesTo ThisFolderOnly
					$sid = $null
					echo $FullPathUW
					# New-Item $NewFullPathUW -ItemType Directory
					# echo "Группа $GroupDepROL"
					# $sid = Get-ADGroup $GroupDepROL -Server $dc
					# Add-NTFSAccess -Path $NewFullPathUW  -Account $sid.sid -AccessRights Read -AppliesTo ThisFolderOnly
					# $sid = $null
					# echo $NewFullPathUW >> $FileNewFolder
				}

				$GroupDepROL = "FA-" + "TeamWorkDocs-" + $DepartmentName + "-RL"
				$FullPathUW = $FullPathUW + $Name1 + "\"
				$NewFullPathUW = $NewFullPathUW + $Name1 + "\"
				if (!(Test-Path $FullPathUW)) {
					New-Item $FullPathUW -ItemType Directory
					echo "Группа $GroupDepROL"
					$sid = Get-ADGroup $GroupDepROL -Server $dc
					Add-NTFSAccess -Path $FullPathUW  -Account $sid.sid -AccessRights Read -AppliesTo ThisFolderOnly
					$sid = $null
					echo $FullPathUW
					New-Item $NewFullPathUW -ItemType Directory
					echo "Группа $GroupDepROL"
					$sid = Get-ADGroup $GroupDepROL -Server $dc
					Add-NTFSAccess -Path $NewFullPathUW  -Account $sid.sid -AccessRights Read -AppliesTo ThisFolderOnly
					$sid = $null
					echo $NewFullPathUW >> $FileNewFolder
				}

			  
				$Name3 = "Руководство департамента"
				$FullPathDirectors = $FullPath1 + $Name3 + "\"
				$NewFullPathDirectors = $NewFullPath1 + $Name3 + "\"
				$GroupDepRukRO = "FA-" + $DepartmentName + "-" + "DeptHead" + "-R"
				$GroupDepRukRW = "FA-" + $DepartmentName + "-" + "DeptHead" + "-RW"
				if (!(Test-Path $FullPathDirectors )) {
					New-Item $FullPathDirectors -ItemType Directory
					echo "Группа $GroupDepRukRO"
					$sid = Get-ADGroup $GroupDepRukRO -Server $dc
					Add-NTFSAccess -Path $FullPathDirectors  -Account $sid.sid -AccessRights ReadAndExecute 
					$sid = $null
					echo "Группа $GroupDepRukRW"
					$sid = Get-ADGroup $GroupDepRukRW -Server $dc
					Add-NTFSAccess -Path $FullPathDirectors  -Account $sid.sid -AccessRights Modify
					$sid = $null
					echo $FullPathDirectors
				
					New-Item $NewFullPathDirectors -ItemType Directory
					echo "Группа $GroupDepRukRO"
					$sid = Get-ADGroup $GroupDepRukRO -Server $dc
					Add-NTFSAccess -Path $NewFullPathDirectors  -Account $sid.sid -AccessRights ReadAndExecute 
					$sid = $null
					echo "Группа $GroupDepRukRW"
					$sid = Get-ADGroup $GroupDepRukRW -Server $dc
					Add-NTFSAccess -Path $NewFullPathDirectors  -Account $sid.sid -AccessRights Modify
					$sid = $null
					echo $NewFullPathDirectors >> $FileNewFolder
				}


				$Name4 = "Документы департамента"
				$FullPathPublicDept = $FullPath1 + $Name4 + "\"
				$NewFullPathPublicDept = $NewFullPath1 + $Name4 + "\"
				$GroupDepPublicRO = "FA-" + $DepartmentName + "-" + "DeptDocs" + "-R"
				$GroupDepPublicRW = "FA-" + $DepartmentName + "-" + "DeptDocs" + "-RW"
				if (!(Test-Path $FullPathPublicDept)) {
					New-Item $FullPathPublicDept -ItemType Directory
					echo "Группа $GroupDepPublicRO"
					$sid = Get-ADGroup $GroupDepPublicRO -Server $dc
					Add-NTFSAccess -Path $FullPathPublicDept  -Account $sid.sid -AccessRights ReadAndExecute 
					$sid = $null
					echo "Группа $GroupDepPublicRW"
					$sid = Get-ADGroup $GroupDepPublicRW -Server $dc
					Add-NTFSAccess -Path $FullPathPublicDept  -Account $sid.sid -AccessRights Modify
					$sid = $null
					echo $FullPathDirectors
				
					New-Item $NewFullPathPublicDept -ItemType Directory
					echo "Группа $GroupDepPublicRO"
					$sid = Get-ADGroup $GroupDepPublicRO -Server $dc
					Add-NTFSAccess -Path $NewFullPathPublicDept  -Account $sid.sid -AccessRights ReadAndExecute 
					$sid = $null
					echo "Группа $GroupDepPublicRW"
					$sid = Get-ADGroup $GroupDepPublicRW -Server $dc
					Add-NTFSAccess -Path $NewFullPathPublicDept  -Account $sid.sid -AccessRights Modify
					$sid = $null
					echo $NewFullPathDirectors >> $FileNewFolder
				}


				$Name2 = $_.IBLOCK_SECTION_NAME_3
				if ($Name2 -notlike $null) {
					$Name2 = $Name2 -replace "'"
					$Otdel = $_.IBLOCK_SECTION_CODE_3
					$FullPath2 = $FullPath1 + $Name2 + "\"
					$NewFullPath2 = $NewFullPath1 + $Name2 + "\"


					$FullPathPublicOtd = $FullPath2
					$NewFullPathPublicOtd = $NewFullPath2
					$GroupOtdPublicRO = "FA-" + $DepartmentName + "-" + $Otdel + "-R"
					$GroupOtdPublicRW = "FA-" + $DepartmentName + "-" + $Otdel + "-RW"
					if (!(Test-Path $FullPathPublicOtd)) {
						New-Item $FullPathPublicOtd -ItemType Directory
						echo "Группа $GroupOtdPublicRO"
						$sid = Get-ADGroup $GroupOtdPublicRO -Server $dc
						Add-NTFSAccess -Path $FullPathPublicOtd  -Account $sid.sid -AccessRights ReadAndExecute 
						$sid = $null
						echo "Группа $GroupOtdPublicRW"
						$sid = Get-ADGroup $GroupOtdPublicRW -Server $dc
						Add-NTFSAccess -Path $FullPathPublicOtd  -Account $sid.sid -AccessRights Modify
						$sid = $null
						echo $FullPath2
					
						New-Item $NewFullPathPublicOtd -ItemType Directory
						echo "Группа $GroupOtdPublicRO"
						$sid = Get-ADGroup $GroupOtdPublicRO -Server $dc
						Add-NTFSAccess -Path $NewFullPathPublicOtd  -Account $sid.sid -AccessRights ReadAndExecute 
						$sid = $null
						echo "Группа $GroupOtdPublicRW"
						$sid = Get-ADGroup $GroupOtdPublicRW -Server $dc
						Add-NTFSAccess -Path $NewFullPathPublicOtd  -Account $sid.sid -AccessRights Modify
						$sid = $null
						echo $NewFullPath2 >> $FileNewFolder
					}

					$FullPathDocOtd = $FullPath2
					$NewFullPathDocOtd = $NewFullPath2
					$GroupOtdDocRO = "FA-" + $DepartmentName + "-" + $Otdel + "-R"
					$GroupOtdDocRW = "FA-" + $DepartmentName + "-" + $Otdel + "-RW"
					if (!(Test-Path $FullPathDocOtd)) {
						New-Item $FullPathDocOtd -ItemType Directory
						echo "Группа $GroupOtdDocRO"
						$sid = Get-ADGroup $GroupOtdDocRO -Server $dc
						Add-NTFSAccess -Path $FullPathDocOtd  -Account $sid.sid -AccessRights ReadAndExecute 
						$sid = $null
						echo "Группа $GroupOtdDocRW"
						$sid = Get-ADGroup $GroupOtdDocRW -Server $dc
						Add-NTFSAccess -Path $FullPathDocOtd  -Account $sid.sid -AccessRights Modify
						$sid = $null
						echo $FullPath2
					
						New-Item $NewFullPathDocOtd -ItemType Directory
						echo "Группа $GroupOtdDocRO"
						$sid = Get-ADGroup $GroupOtdDocRO -Server $dc
						Add-NTFSAccess -Path $NewFullPathDocOtd  -Account $sid.sid -AccessRights ReadAndExecute 
						$sid = $null
						echo "Группа $GroupOtdDocRW"
						$sid = Get-ADGroup $GroupOtdDocRW -Server $dc
						Add-NTFSAccess -Path $NewFullPathDocOtd  -Account $sid.sid -AccessRights Modify
						$sid = $null
						echo $NewFullPath2 >> $FileNewFolder
					}
				}
			}


			$Name1 = "Обмен"
			$GroupDepRO = "FA-" + "Exchge" + "-R"
			$GroupDepRW = "FA-" + "Exchge" + "-RW"
			$FullPath1 = $Path + $Name1 + "\"
			$NewFullPath1 = $NewPath + $Name1 + "\"
			if (!(Test-Path $FullPath1)) {
				New-Item $FullPath1 -ItemType Directory
				echo "Группа $GroupDepRO"
				$sid = Get-ADGroup $GroupDepRO -Server $dc
				Add-NTFSAccess -Path $FullPath1  -Account $sid.sid -AccessRights ReadAndExecute 
				$sid = $null
				echo "Группа $GroupDepRW"
				$sid = Get-ADGroup $GroupDepRW -Server $dc
				Add-NTFSAccess -Path $FullPath1  -Account $sid.sid -AccessRights Modify
				$sid = $null
				echo $FullPath1
			
				New-Item $NewFullPath1 -ItemType Directory
				echo "Группа $GroupDepRO"
				$sid = Get-ADGroup $GroupDepRO -Server $dc
				Add-NTFSAccess -Path $NewFullPath1  -Account $sid.sid -AccessRights ReadAndExecute 
				$sid = $null
				echo "Группа $GroupDepRW"
				$sid = Get-ADGroup $GroupDepRW -Server $dc
				Add-NTFSAccess -Path $NewFullPath1  -Account $sid.sid -AccessRights Modify
				$sid = $null
				echo $NewFullPath1 >> $FileNewFolder
			}

			$Name1 = "Общие документы"
			$GroupDepRO = "FA-" + "PublicDocs" + "-R"
			$GroupDepRW = "FA-" + "PublicDocs" + "-RW"
			$FullPath1 = $Path + $Name1 + "\"
			$NewFullPath1 = $NewPath + $Name1 + "\"
			if (!(Test-Path $FullPath1)) {
				New-Item $FullPath1 -ItemType Directory
				echo "Группа $GroupDepRO"
				$sid = Get-ADGroup $GroupDepRO -Server $dc
				Add-NTFSAccess -Path $FullPath1  -Account $sid.sid -AccessRights ReadAndExecute 
				$sid = $null
				echo "Группа $GroupDepRW"
				$sid = Get-ADGroup $GroupDepRW -Server $dc
				Add-NTFSAccess -Path $FullPath1  -Account $sid.sid -AccessRights Modify
				$sid = $null
				echo $FullPath1
			
				New-Item $NewFullPath1 -ItemType Directory
				echo "Группа $GroupDepRO"
				$sid = Get-ADGroup $GroupDepRO -Server $dc
				Add-NTFSAccess -Path $NewFullPath1  -Account $sid.sid -AccessRights ReadAndExecute 
				$sid = $null
				echo "Группа $GroupDepRW"
				$sid = Get-ADGroup $GroupDepRW -Server $dc
				Add-NTFSAccess -Path $NewFullPath1  -Account $sid.sid -AccessRights Modify
				$sid = $null
				echo $NewFullPath1 >> $FileNewFolder
			}


			if (Test-Path "$FileNewFolder") {
				$Server = "mail.zzz" # SMTP Сервер
				$From = "@.ru" # Адрес отправителя
				$To1 = "n@.ru"
				$Subject = "Созданы новые отделы" # Тема сообщения
				$Body = "Необходимо скопировать папки для новых отделов на сетевой диск. <br> 
			    Папки расположены в $NewPath на сервере 01 <br> 
			    После копирования очистить папку $NewPath <br>
			    Список папок в приложенном файле."

				$SmtpClient = New-Object System.Net.Mail.SmtpClient
				$Message = New-Object System.Net.Mail.MailMessage
				$SmtpClient.Host = $Server
				$Message.IsBodyHtml = $true
				$Message.From = $From
				$Message.To.Add($To1)
				$Message.To.Add($To2)
				$Message.To.Add($To3)
				$Message.Subject = $Subject
				$Message.Body = $Body | Format-List | Out-String
				$file = "$FileNewFolder"
				$att = new-object Net.Mail.Attachment($file)
				$Message.Attachments.Add($att)
				$SmtpClient.Send($Message)
			}
			Copy-Item $Filename $SuccessPath
		}
	}
}

