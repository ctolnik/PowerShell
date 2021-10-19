clear
Remove-Item result2.csv
$baseOU = "OU=Пользователи,O"
$users = Import-Csv -Path users.csv -Encoding UTF8
$OUs = Get-ADOrganizationalUnit -SearchBase $baseOU -Filter * -Properties description, CanonicalName | Sort-Object CanonicalName -Descending
$adusers = $null
$adusers = @()
foreach ($user in $users) {
	$ADUser = Get-ADUser -Identity $user.USERNAME -Properties distinguishedName
	$adusers += $aduser
}
$text = "CN;ID;Description;Count"
$text >> result2.csv
$neddecrease = 0
foreach ($OU in $OUs) {

	$count = 0
	foreach ($aduser in $adusers) {
		if ($ADUser -match $OU.DistinguishedName) {
			$count += 1
		}
	}
	
	$OrgUnit = $OU.CanonicalName.Substring($OU.CanonicalName.indexof("Пользователи") + 13)		
	if (($neddecrease -eq 1) -and ($outodecrease -eq $OrgUnit)) {
		$count = $count - $counttodecrease
		$outodecrease = $OrgUnit.Substring(0, $OrgUnit.lastindexof("/"))
	}



	if (($count -gt 50) -and ($OrgUnit -like "*/*")) {	
		$text = $OU.CanonicalName + ";" + $OrgUnit + ";" + $OU.Description + ";" + $count
		$text >> result2.csv
		$neddecrease = 1
		$counttodecrease = $count
		$outodecrease = $OrgUnit.Substring(0, $OrgUnit.lastindexof("/"))
	}

	if ($OrgUnit -Notlike "*/*") {
		$text = $OU.CanonicalName + ";" + $OrgUnit + ";" + $OU.Description + ";" + $count
		$text >> result2.csv
	}
}
