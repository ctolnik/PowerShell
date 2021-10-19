# Скрипт позволяет получить текущие сессии на RDGW.
# Результат записываем в файл дня.

# Объявляем переменные
$date = Get-Date -Format "dd.MM.yyyy"
$gw1 = "*-SRV-RDGW1"  # Сервер 1 с которого собираем статистику
$gw2 = "*-SRV-RDGW2"  # Сервер 2 с которого собираем статистику
$Logname = "C:\Scripts\RDGW\Gathering\Counts_" + (Get-Date -Format dd.MM.yyyy) + ".csv"

# Вызываем функцию сбора данных о подключениях
Function Get-RDGConnections {            
    [CmdletBinding(DefaultParameterSetName = 'Computer', SupportsTransactions = $false)]            
    param(            
        [Parameter(ParameterSetName = 'Computer', ValueFromPipeline = $true, Mandatory = $false, Position = 0)]            
        [system.string[]]${ComputerName},            
            
        [Parameter(ParameterSetName = 'Computer', ValueFromPipeline = $false, Mandatory = $false, Position = 1)]            
        [System.Management.Automation.PSCredential]$Credential = $null            
    )            
            
    begin {            
        # Check if we've got the value from the pipeline            
        $direct = $PSBoundParameters.ContainsKey('ComputerName')            
            
        # Build a hashtable for splatting            
        $otherparams = @{}            
        if ($credential) {            
            $otherparams += @{Credential = $Credential }            
        }            
            
    }            
    process {            
        $resultsar = @()            
        foreach ($computer in $ComputerName) {            
            $allRDGconnections = @()            
            # Write-Verbose -Message "Dealing with $computer" -Verbose:$true            
            try {            
                # http://social.technet.microsoft.com/Forums/en-US/winserverpowershell/thread/85e0c2bf-abca-4cf9-9355-cb066344a7d5/            
                $allRDGconnections = @(Get-WmiObject -class "Win32_TSGatewayConnection" -namespace "root\cimv2\TerminalServices" -ComputerName $computer -Authentication 6 -ErrorAction Stop @otherparams)            
            }             
            catch {            
                # WMI was unable to retrieve the information            
                switch ($_) {            
                    # sort out most common errors and return qualified information            
                    { $_.Exception.ErrorCode -eq 0x800706ba } { $reason = 'Unavailable (offline, firewall)' }            
                    { $_.CategoryInfo.Reason -eq 'UnauthorizedAccessException' } { $reason = 'Access denied' }            
                    # {          $_.Exception.ErrorCode -eq 0x80070005} { $reason = 'Access denied' }            
                    # return all other non-common errors            
                    default { $reason = $_.Exception.Message }            
                } # end of switch            
                if ($direct) { Write-Host -ForegroundColor Red -Object ("Failed to connected to $computer because $reason") }            
            } # end of catch            
            if ($allRDGconnections.Count -ne 0) {            
                foreach ($item in $allRDGconnections) {            
                    # Write-Verbose -Message "Adding $($item.ConnectedResource)" -Verbose:$true            
                    $resultsar += New-Object -TypeName PSObject -Property @{            
                        ViaRDGServer       = $computer            
                        ConnectionID       = $item.ConnectionKey            
                        UserName           = $item.FullUserName            
                        TargetComputer     = $item.ConnectedResource            
                        UserID             = $item.UserName            
                        ClientIPAddress    = $item.ClientAddress               
                        ConnectionDuration = [System.Management.ManagementDateTimeConverter]::ToTimeSpan(($item.ConnectionDuration))            
                        ConnectedOn        = $item.ConvertToDateTime($item.ConnectedTime)            
                        IdleTime           = [System.Management.ManagementDateTimeConverter]::ToTimeSpan(($item.IdleTime))            
                        TargetPort         = $item.ConnectedPort            
                        KilobytesReceived  = $item.NumberOfKilobytesReceived            
                        KilobytesSent      = $item.NumberOfKilobytesSent            
                    }            
                }            
            }
            else {            
                if ($direct) { Write-Host -ForegroundColor Yellow -Object ("No body connected on $computer") }            
            }            
        } # end of foreach $computer            
        # Output results            
        if ($resultsar -ne $null) {            
            return $resultsar            
        }            
    }            
    end {}            
} # end of function


$Sessions = Get-RDGConnections -ComputerName $gw1
$Sessions += Get-RDGConnections -ComputerName $gw2
$byRDG = $Sessions | group ViaRDGServer


$stats = @()   
foreach ($RDG in $byRDG) {
    $stats += New-Object -TypeName PSObject -Property @{           
        RDGServerName = $RDG.Name         
        Count         = $RDG.Count   
        DateTime      = [DateTime]$DateTime = Get-Date
    }
}


$stats | Export-Csv $Logname  -Append -nti -Delimiter ";" -Encoding UTF8 