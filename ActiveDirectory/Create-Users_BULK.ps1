Import-Module ActiveDirectory
# OU где создавать уз
#$path = "OU=*x, OU=111 xx,DC=xxx,DC=x"
$path = "OU=SKPD,OU=System_accounts,OU=www,OU=xxx zzz,DC=xxx,DC=444"
#Функция транслитерации
function global:Translit {
    param([string]$inString)
    $Translit = @{
        [char]'а' = "a"
        [char]'А' = "A"
        [char]'б' = "b"
        [char]'Б' = "B"
        [char]'в' = "v"
        [char]'В' = "V"
        [char]'г' = "g"
        [char]'Г' = "G"
        [char]'д' = "d"
        [char]'Д' = "D"
        [char]'е' = "e"
        [char]'Е' = "E"
        [char]'ё' = "yo"
        [char]'Ё' = "Yo"
        [char]'ж' = "zh"
        [char]'Ж' = "Zh"
        [char]'з' = "z"
        [char]'З' = "Z"
        [char]'и' = "i"
        [char]'И' = "I"
        [char]'й' = "j"
        [char]'Й' = "J"
        [char]'к' = "k"
        [char]'К' = "K"
        [char]'л' = "l"
        [char]'Л' = "L"
        [char]'м' = "m"
        [char]'М' = "M"
        [char]'н' = "n"
        [char]'Н' = "N"
        [char]'о' = "o"
        [char]'О' = "O"
        [char]'п' = "p"
        [char]'П' = "P"
        [char]'р' = "r"
        [char]'Р' = "R"
        [char]'с' = "s"
        [char]'С' = "S"
        [char]'т' = "t"
        [char]'Т' = "T"
        [char]'у' = "u"
        [char]'У' = "U"
        [char]'ф' = "f"
        [char]'Ф' = "F"
        [char]'х' = "h"
        [char]'Х' = "H"
        [char]'ц' = "c"
        [char]'Ц' = "C"
        [char]'ч' = "ch"
        [char]'Ч' = "Ch"
        [char]'ш' = "sh"
        [char]'Ш' = "Sh"
        [char]'щ' = "sch"
        [char]'Щ' = "Sch"
        [char]'ъ' = ""
        [char]'Ъ' = ""
        [char]'ы' = "y"
        [char]'Ы' = "Y"
        [char]'ь' = ""
        [char]'Ь' = ""
        [char]'э' = "e"
        [char]'Э' = "E"
        [char]'ю' = "yu"
        [char]'Ю' = "Yu"
        [char]'я' = "ya"
        [char]'Я' = "Ya"
    }
    $outCHR = ""
    foreach ($CHR in $inCHR = $inString.ToCharArray()) {
        if ($Translit[$CHR] -cne $Null )
        { $outCHR += $Translit[$CHR] }
        else
        { $outCHR += $CHR }
    }
    Write-Output $outCHR
}

# Загружаем список из CSV
$Users = @()
$Users = Import-Csv -Delimiter ";" -Path "C:\Scripts\Users3.txt" -Encoding UTF8

# Цикл создания учётки 
foreach ($user in $users)
{

    $Password = '1234'
    $UserFirstname = $User.FirstName
    $UserLastName = $User.LastName
    $TransName = Translit($User.FirstName)
    $TransSurname = Translit($User.LastName)
    $TransGivenName = Translit($User.MiddleName)
    $Detailedname = $TransSurname + " " + $TransName + " " + $TransGivenName
    $description = "xxx SKPD Account"
    $SAM = "xxx-skpd-" + $TransSurname
    $UPN = $SAM + "@xxx.ru"
    New-ADUser -Name $Detailedname -SamAccountName $SAM -UserPrincipalName $UPN -DisplayName $Detailedname -GivenName $UserFirstname -Surname  $UserLastName -description $description  -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -Path $path
}

