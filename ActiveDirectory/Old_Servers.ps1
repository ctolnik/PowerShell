# Переменные
$date = (get-date).adddays(-60) # количество дней, когда пароль не менялся. Можно увеличить, если выросли ложные срабатывания.
$serversOU = ""
$DisabledOU = "" # OU куда перемещаем компы.

get-adcomputer -SearchBase $serversOU  -filter { passwordlastset -lt $date } -properties passwordlastset  |  ForEach-Object { Disable-ADAccount $_ ; Move-ADObject $_ -TargetPath $DisabledOU } 
 

