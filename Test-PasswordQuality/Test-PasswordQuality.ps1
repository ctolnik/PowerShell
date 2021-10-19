clear
Import-Module D:\distrib\DSInternals\DSInternals.psd1
$DictFile = "D:\distrib\DSInternals\pwd_for_scan.txt"
$DC = "xxxx-dc01"
$Domain = "DC=xxx,DC=zzz"
$Dict = Get-Content $DictFile | ConvertTo-NTHashDictionary
Get-ADReplAccount -All -Server $DC -NamingContext $Domain | Test-PasswordQuality -WeakPasswordHashes $Dict -ShowPlainTextPasswords -IncludeDisabledAccounts