get-process -ComputerName  | Sort CPU -descending | Select -first 5 -Property ID,ProcessName,CPU | format-table -autosize
