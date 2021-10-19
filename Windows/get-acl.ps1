#Поиск папок, поиск ACL групп для папков. Вывод списка пользователей из ACL


clear
$string = "Path;Read;Write"
$string >> D:\acls.csv
#$directories=Get-ChildItem \\srvi-dfs05\share -Recurse -Directory
$directories = Get-ChildItem "\\srvi-dfs05\share\Совместная работа\Служба безопасности и режима" -Recurse -Directory
foreach ($directory in $directories) {
    $access = $null
    $access = (Get-Acl $directory.FullName).Access
    if ($access -ne $null) {
        $fullgroup = $null

        foreach ($acl in $access) {
            if ($acl.identityReference -like "xxx\*-R") {
                $fullgroup = $acl.identityReference.Value

                $group = $fullgroup.substring($fullgroup.indexof("\") + 1)
                $usersR = (Get-ADGroupMember $group).name
            }
            if ($acl.identityReference -like "xxx\*-RW") {
                $fullgroup = $acl.identityReference.Value
                $group = $fullgroup.substring($fullgroup.indexof("\") + 1)

                $usersW = (Get-ADGroupMember $group).name
            }
        }
        $string = $directory.FullName + ";" + $usersR + ";" + $usersW
        $string >> D:\acls.csv
    }
}