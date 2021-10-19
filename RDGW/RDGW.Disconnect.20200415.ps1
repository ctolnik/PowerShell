$allRDGconnections = Get-WmiObject -class "Win32_TSGatewayConnection" -namespace "root\cimv2\TerminalServices" -ComputerName "-SRV-RDGW1"
$allRDGconnections += Get-WmiObject -class "Win32_TSGatewayConnection" -namespace "root\cimv2\TerminalServices" -ComputerName "-SRV-RDGW2"
$allRDGconnections.Disconnect() 
