clear
$baseOU = "OU="
$users = Import-Csv -Path users.csv -Encoding UTF8
$OUs = Get-ADOrganizationalUnit -SearchBase $baseOU -Filter * -Properties description, CanonicalName | Sort-Object CanonicalName -Descending
$adusers = $null
$adusers = @()
$mol1 = @()
foreach ($user in $users) {
	$ADUser = Get-ADUser -Identity $user.USERNAME -Properties distinguishedName
	$adusers += $aduser
}
$neddecrease = 0
foreach ($OU in $OUs) {

	$count = 0
	foreach ($aduser in $adusers) {
		if ($ADUser -match $OU.DistinguishedName) {
			#$OU.DistinguishedName
			$mol1 += $aduser.name
			$count += 1
			#$count
		}
	}


}
$mol1 | Select-Object -Unique
$count
