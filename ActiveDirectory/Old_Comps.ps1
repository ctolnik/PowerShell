# Переменные
$date = (get-date).adddays(-45) # количество дней, когда пароль не менялся. Можно увеличить, если выросли ложные срабатывания.
$DisabledOU = "" # OU куда перемещаем компы.

#get-adcomputer -SearchBase "" -filter {passwordlastset -lt $date} -properties passwordlastset | select name, passwordlastset | sort passwordlastset | Export-Csv -Path C:\Scripts\Gathering\comps.csv -Encoding UTF8 -Delimiter ";"

get-adcomputer -SearchBase "" -filter { passwordlastset -lt $date } -properties passwordlastset  |  ForEach-Object { Disable-ADAccount $_ ; Move-ADObject $_ -TargetPath $DisabledOU } 
 
#Move-ADObjec TargetPath ""
