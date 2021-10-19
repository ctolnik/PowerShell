# Переменные
$date = (get-date).adddays(-45) # количество дней, когда пароль не менялся. Можно увеличить, если выросли ложные срабатывания.
$Computers = get-adcomputer -SearchBase "OU=MMZ,OU=Domain Computers,DC=npo,DC=izhmash" -filter { passwordlastset -gt $date -and enabled -eq $true } -properties IPv4Address | ? IPv4Address -ne $null | Select-Object Name, IPv4Address 
$Computers | gm
$Computers.Count
$LiveComputers.Count

$LiveComputers = @()

foreach ($Computer in $Computers) {
    $CompIP = $null
    $CompIP = $Computer.IPv4Address 
    if (Test-NetConnection -ComputerName $CompIP -InformationLevel Quiet ) {
        $LiveComputers += $Computer
    }

}

$LiveComputers | Select-Object Name | Export-Csv -Path C:\Scripts\Gathering\livedcomps.csv -Encoding UTF8 -Delimiter ";" -NoTypeInformation

$LiveComputers | Select-Object Name | Out-File -FilePath C:\Scripts\Gathering\livedcomps2.txt
