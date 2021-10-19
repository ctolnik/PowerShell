# Скрипт Кокорникова И.В.  
# Подключаем модуль AD т.к. ищем компы там

Import-Module ActiveDirectory

#OU где мы будем искать компы
$OU1 = "OU=Макр*u"
$OU2 = "OU=D01,OU=Se*ru"


# Включаем или коментируем для логирования в файл где не удалось выполнить проверку.
$ErrorLog = 'c:\*.csv'

$date_with_offset = (Get-Date).AddDays(-90)

# А который сегодня день?
$TodaysDate = Get-Date


# Проводим поиск серверов и запись его в переменную, если хотим искать только в одной OU то добавляем параметр  -SearchScope 0
$servers_1 = Get-ADComputer -searchbase $OU1   -Filter { OperatingSystem -Like '*Windows Server*' -and LastLogonDate -ge $date_with_offset } -Properties OperatingSystem, LastLogonDate | Select Name, LastLogonDate, OperatingSystem | Sort -Descending LastLogonDate
$servers_2 = Get-ADComputer -searchbase $OU2   -Filter { OperatingSystem -Like '*Windows Server*' -and Name -like "D01MOPS*" } -Properties OperatingSystem, LastLogonDate | Select Name, LastLogonDate, OperatingSystem | Sort -Descending LastLogonDate

$servers = $servers_1 + $servers_2

$servers =
#  $servers    | Format-Table -AutoSize
# Вытаскиваем имена по кому будем бегать.
$ComputerName = $servers.name



# Цикл перебора

Foreach ($Computer in $ComputerName) {
	Try {
        
		if ((Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue).StatusCode –eq 0) {
			## Setting pending values to false to cut down on the number of else statements
			$CompPendRen, $PendFileRename, $Pending, $SCCM = $false, $false, $false, $false
                        
			## Установка CBSRebootPend равным null, так как не все версии Windows имеет это значение
			$CBSRebootPend = $null
						
			## Опрашиванем WMI на версию build 
			$WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

			## Подключение реестра к серверу
			$HKLM = [UInt32] "0x80000002"
			$WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
						
			## Если Vista / 2008 и выше запросить ключ Reg CBS
			If ([Int32]$WMI_OS.BuildNumber -ge 6001) {
				$RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
				$CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"		
			}
							
			## Запрос WUAU из реестра
			$RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
			$WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"
						
			## Запрос PendingFileRenameOperations из реестра
			$RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM, "SYSTEM\CurrentControlSet\Control\Session Manager\", "PendingFileRenameOperations")
			$RegValuePFRO = $RegSubKeySM.sValue

			## Запрос ключа JoinDomain key из registry. Эти ключи присутствуют, если в ожидании перезагрузки от операции присоединения к домену
			$Netlogon = $WMI_Reg.EnumKey($HKLM, "SYSTEM\CurrentControlSet\Services\Netlogon").sNames
			$PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

			## Запрос ComputerName и ActiveComputerName из реестра
			$ActCompNm = $WMI_Reg.GetStringValue($HKLM, "SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\", "ComputerName")            
			$CompNm = $WMI_Reg.GetStringValue($HKLM, "SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\", "ComputerName")


			# Новый отдел, чтобы было видно, сколько сервер "не единого разрыва".
			$operatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $computer
			$RTime = [Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LastBootUpTime)
			#$LocalTime=[Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LocalDateTime)
			#$CurTimeZone=$operatingSystem.CurrentTimeZone
			$StatusNow = ""		    
			$R = $RTime
			$Z = $TodaysDate
			$DayNotRebooted = (New-TimeSpan -Start $R -End $Z).Days
			IF ($DayNotRebooted -ge 30) {
				$StatusNow = "ВНИМАНИЕ: 30 дней без перезагруки"
			}
		


			If (($ActCompNm -ne $CompNm) -or $PendDomJoin) {
				$CompPendRen = $true
			}
						
			## Если pendingfilerenameoperations имеет значение переменной $RegValuePFRO в $true
			If ($RegValuePFRO) {
				$PendFileRename = $true
			}

			##Определение состояния ожидания перезагрузки клиента SCCM
			## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
			$CCMClientSDK = $null
			$CCMSplat = @{
				NameSpace    = 'ROOT\ccm\ClientSDK'
				Class        = 'CCM_ClientUtilities'
				Name         = 'DetermineIfRebootPending'
				ComputerName = $Computer
				ErrorAction  = 'Stop'
			}
			## Try CCMClientSDK
			Try {
				$CCMClientSDK = Invoke-WmiMethod @CCMSplat
			}
			Catch [System.UnauthorizedAccessException] {
				$CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue
				If ($CcmStatus.Status -ne 'Running') {
					Write-Warning "$Computer`: Error - CcmExec service is not running."
					$CCMClientSDK = $null
				}
			}
			Catch {
				$CCMClientSDK = $null
			}

			If ($CCMClientSDK) {
				If ($CCMClientSDK.ReturnValue -ne 0) {
					Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"          
				}
				If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
					$SCCM = $true
				}
			}
            
			Else {
				$SCCM = $null
			}

			## Создание пользовательского PSObject и Select-Object Splat
			$SelectSplat = @{
				Property = (
					'Computer',
					'CBServicing',
					'WindowsUpdate',
					'CCMClientSDK',
					'PendComputerRename',
					'PendFileRename',
					'PendFileRenVal',
					'DayNotRebooted',
					'StatusNow',
					'RebootPending'
				)
			}
			New-Object -TypeName PSObject -Property @{
				Computer           = $WMI_OS.CSName
				CBServicing        = $CBSRebootPend
				WindowsUpdate      = $WUAURebootReq
				CCMClientSDK       = $SCCM
				PendComputerRename = $CompPendRen
				PendFileRename     = $PendFileRename
				PendFileRenVal     = $RegValuePFRO
				DayNotRebooted     = $DayNotRebooted
				StatusNow          = $StatusNow
				RebootPending      = ($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
			} | Select-Object @SelectSplat

		}
	}
 Catch {
		Write-Warning "$Computer`: $_"
		## If $ErrorLog, log the file to a user specified location/path
		If ($ErrorLog) {
			Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog 
		}				
	}
		
}## Окончание перебора ($Computer in $ComputerName)			
