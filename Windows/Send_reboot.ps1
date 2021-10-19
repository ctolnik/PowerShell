
$Reboots = C:\Puppet\PendigReboot.ps1 |  Where-Object RebootPending -ne $false  



##################################################################
#                   Notification Settings
##################################################################

# Enable notification (Optional)
$EnableNotification = $True

# Email SMTP server
$SMTPServer = "smtp.**.ru"

# Email FROM
$EmailFrom = "veeambackup-r77@*.ru" 

# Email TO
$EmailTo = "osa-r77@**.ru"

# Email subject
$EmailSubject = "Пришла пора перезагружать сервера …*"

# Вложение
$file = "c:\p*ь.csv"
$att = new-object Net.Mail.Attachment($file)

##################################################################
#                   Email formatting 
##################################################################

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$col = $Reboots.Count
$cl2 = $Reboots | where { $_.WindowsUpdate -like "True" } | select Computer
$col2 = ($cl2.Computer).Count
$Body = $Reboots | ConvertTo-Html -head $style | Out-String
#$Body = $Reboots

$user = 'veeambackup-r77@main.***.ru'
$pass = '*********'
$SMTPPort = "587"

$message = New-Object System.Net.Mail.MailMessage
$message.subject = $EmailSubject
$message.body = "<p><b>Total number of servers to reboot: <font color=orange>$col</font>. But for OS Update only <font color=red>$col2 </font></b></p></br> $Body"
$message.to.add($EmailTo)
$message.from = $EmailFrom
$message.Attachments.Add($att)
$message.IsBodyHTML = $True

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($user, $pass);
$smtp.send($message)
