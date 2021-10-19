# Скрипт для добавления уз компьютеров в группу AD
# Определяем переменные
$GroupName = ‘MMZ-SCCM-APP-FineReader’ # Группу которую наполняем
$Comps = Get-Content C:\Scripts\Gathering\comps2.csv # Компы список, который добавить нужно

# Компы добавляються со значком $, поэтому добавляем в массив данных для каждого имени символ $
$NewComps = @()
foreach ($comp in $Comps)
{$LengComp = $comp.Length
$NewComps += $Comp.Insert($LengComp,"$")
}

# Добавление в группу
Add-AdGroupMember -Identity $GroupName -Members $NewComps
