Import-Module jiraps

#функция изменения размера изображения

Function Set-ImageSize
{
    <#
	.SYNOPSIS
	    Resize image file.

	.DESCRIPTION
	    The Set-ImageSize cmdlet to set new size of image file.
		
	.PARAMETER Image
	    Specifies an image file. 

	.PARAMETER Destination
	    Specifies a destination of resized file. Default is current location (Get-Location).
	
	.PARAMETER WidthPx
	    Specifies a width of image in px. 
		
	.PARAMETER HeightPx
	    Specifies a height of image in px.		
	
	.PARAMETER DPIWidth
	    Specifies a vertical resolution. 
		
	.PARAMETER DPIHeight
	    Specifies a horizontal resolution.	
		
	.PARAMETER Overwrite
	    Specifies a destination exist then overwrite it without prompt. 
		
	.PARAMETER FixedSize
	    Set fixed size and do not try to scale the aspect ratio. 

	.PARAMETER RemoveSource
	    Remove source file after conversion. 
		
	.EXAMPLE
		PS C:\> Get-ChildItem 'P:\test\*.jpg' | Set-ImageSize -Destination "p:\test2" -WidthPx 300 -HeightPx 375 -Verbose
		VERBOSE: Image 'P:\test\00001.jpg' was resize from 236x295 to 300x375 and save in 'p:\test2\00001.jpg'
		VERBOSE: Image 'P:\test\00002.jpg' was resize from 236x295 to 300x375 and save in 'p:\test2\00002.jpg'
		VERBOSE: Image 'P:\test\00003.jpg' was resize from 236x295 to 300x375 and save in 'p:\test2\00003.jpg'
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
	#>
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]		
	Param
	(
		[parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
		[Alias("Image")]	
		[String[]]$FullName,
		[String]$Destination = $(Get-Location),
		[Switch]$Overwrite,
		[Int]$WidthPx,
		[Int]$HeightPx,
		[Int]$DPIWidth,
		[Int]$DPIHeight,
		[Switch]$FixedSize,
		[Switch]$RemoveSource
	)

	Begin
	{
		[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
		#[void][reflection.assembly]::loadfile( "C:\Windows\Microsoft.NET\Framework\v2.0.50727\System.Drawing.dll")
	}
	
	Process
	{

		Foreach($ImageFile in $FullName)
		{
			If(Test-Path $ImageFile)
			{
				$OldImage = new-object System.Drawing.Bitmap $ImageFile
				$OldWidth = $OldImage.Width
				$OldHeight = $OldImage.Height
				
				if($WidthPx -eq $Null)
				{
					$WidthPx = $OldWidth
				}
				if($HeightPx -eq $Null)
				{
					$HeightPx = $OldHeight
				}
				
				if($FixedSize)
				{
					$NewWidth = $WidthPx
					$NewHeight = $HeightPx
				}
				else
				{
					if($OldWidth -lt $OldHeight)
					{
						$NewWidth = $WidthPx
						[int]$NewHeight = [Math]::Round(($NewWidth*$OldHeight)/$OldWidth)
						
						if($NewHeight -gt $HeightPx)
						{
							$NewHeight = $HeightPx
							[int]$NewWidth = [Math]::Round(($NewHeight*$OldWidth)/$OldHeight)
						}
					}
					else
					{
						$NewHeight = $HeightPx
						[int]$NewWidth = [Math]::Round(($NewHeight*$OldWidth)/$OldHeight)
						
						if($NewWidth -gt $WidthPx)
						{
							$NewWidth = $WidthPx
							[int]$NewHeight = [Math]::Round(($NewWidth*$OldHeight)/$OldWidth)
						}						
					}
				}

				$ImageProperty = Get-ItemProperty $ImageFile				
				$SaveLocation = Join-Path -Path $Destination -ChildPath ($ImageProperty.Name)
                
                <#убрать проверку на перезапись файла

				If(!$Overwrite)
				{
					If(Test-Path $SaveLocation)
					{
						$Title = "A file already exists: $SaveLocation"
							
						$ChoiceOverwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
						$ChoiceCancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
						$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite)		
						If(($host.ui.PromptForChoice($Title, $null, $Options, 1)) -eq 0)
						{
							Write-Verbose "Image '$ImageFile' exist in destination location - skiped"
							Continue
						} #End If ($host.ui.PromptForChoice($Title, $null, $Options, 1)) -eq 0
					} #End If Test-Path $SaveLocation
				}#> #End If !$Overwrite	
				
				$NewImage = new-object System.Drawing.Bitmap $NewWidth,$NewHeight

				$Graphics = [System.Drawing.Graphics]::FromImage($NewImage)
				$Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
				$Graphics.DrawImage($OldImage, 0, 0, $NewWidth, $NewHeight) 

				$ImageFormat = $OldImage.RawFormat
				$OldImage.Dispose()
				if($DPIWidth -and $DPIHeight)
				{
					$NewImage.SetResolution($DPIWidth,$DPIHeight)
				} #End If $DPIWidth -and $DPIHeight
				
				$NewImage.Save($SaveLocation,$ImageFormat)
				$NewImage.Dispose()
				Write-Verbose "Image '$ImageFile' was resize from $($OldWidth)x$($OldHeight) to $($NewWidth)x$($NewHeight) and save in '$SaveLocation'"
				
				If($RemoveSource)
				{
					Remove-Item $Image -Force
					Write-Verbose "Image source '$ImageFile' was removed"
				} #End If $RemoveSource
			}
		}

	} #End Process
	
	End{}
}

$log = (Get-Date -Format G) +"`r`n"

#подключение к jira

$JiraSrv = 'https://sd.kalashnikovconcern.ru/'
Set-JiraConfigServer -Server $JiraSrv
$Username = "kk-servphoto"
$Password = ConvertTo-SecureString -String "Gsr!seyq2020" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $Password
New-JiraSession -Credential $Cred | Out-Null

#подразделения

$kk = "*АО 'Концерн 'Калашников'*"
$imz = "*АО 'Ижевский механический завод'*"
$mmz = "*АО 'Мытищинский машиностроительный завод'*"

#каталоги

$pathkk = "\\npo\system$\Photo\PhotoAddPortal"
$pathimz = "\\npo\system$\1C-AD\IMZ\Photo\PhotoAddPortal"
$pathmmz = "\\npo\system$\1C-AD\MMZ\Photo\PhotoAddPortal"
#$pathkk = "C:\Users\Default\Desktop\scripts\photo\kk"
#$pathimz = "C:\Users\Default\Desktop\scripts\photo\imz"

#получаем все задачи по фильтру

$SPHs = Get-JiraIssue -Query "project = SPH AND status = Выполнено AND Resolution = Done AND resolved >= -30m"
$log += "Найденные запросы для замены фото:`r`n"
if ($SPHs -eq $null){
    $log += "Отсутствуют новые запросы`r`n"
}else {
    $log += $SPHs +"`r`n"
}

#обрезка фото для AD

function Set-photoAD ($file,$pathout){
    $filename = (get-item $File).Name 
    $img = [Drawing.Image]::FromFile($File)
    $bmp = New-Object Drawing.Bitmap $img 
    $fileout = New-Object IO.FileStream("$Pathout$filename", [IO.FileMode]::Create)
    $bmp.Clone((New-Object Drawing.Rectangle 0, 0, $img.width, $img.width), [Drawing.Imaging.PixelFormat]::Undefined).Save($fileout, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $fileout.Close()
    $login = $filename.Split("_")[0]
    Set-ADUser $login -Replace @{thumbnailPhoto=([byte[]](Get-Content $fileout.Name -Encoding byte))}
}

#перебор задач

foreach ($sph in $SPHs){

    #определяем площадку и копируем фото в каталог для загрузки на портал и AD

    $task = get-jiraissue $sph 
    $desc = $task.Description

    if ($desc -like $kk){
        #Get-JiraIssueAttachment -Issue $sph | Set-ImageSize -Destination $pathkk -WidthPx 250 -HeightPx 375 -Verbose
        Get-JiraIssueAttachmentFile (Get-JiraIssueAttachment -Issue $sph) -Path $pathkk
        $pathkk+"\"+(Get-JiraIssueAttachment -Issue $sph).filename | Set-ImageSize -Destination $pathkk -WidthPx 250 -HeightPx 375 -Verbose
        $log +="Обновление фото на портале: Файл "+(Get-JiraIssueAttachment -Issue $sph).filename+" добавлен в каталог "+$pathkk +"`r`n"
        Copy-Item -Path $pathkk+"\"+(Get-JiraIssueAttachment -Issue $sph).filename -Destination "\\npo\system$\Photo\PhotoAddAD\"+(Get-JiraIssueAttachment -Issue $sph).filename -Force
        $log +="Обновление фото в AD: Файл "+(Get-JiraIssueAttachment -Issue $sph).filename+" добавлен в каталог \\npo\system$\Photo\PhotoAddAD\ `r`n"
    }
    if ($desc -like $imz){
        #Get-JiraIssueAttachment -Issue $sph | Set-ImageSize -Destination $pathimz -WidthPx 250 -HeightPx 375 -Verbose
        Get-JiraIssueAttachmentFile (Get-JiraIssueAttachment -Issue $sph) -Path $pathimz
        $pathimz+"\"+(Get-JiraIssueAttachment -Issue $sph).filename | Set-ImageSize -Destination $pathimz -WidthPx 250 -HeightPx 375 -Verbose
        $log +="Обновление фото на портале: Файл "+(Get-JiraIssueAttachment -Issue $sph).filename+" добавлен в каталог "+$pathimz +"`r`n"
        Set-photoAD -file $pathimz+"\"+(Get-JiraIssueAttachment -Issue $sph).filename -pathout "\\npo\system$\1C-AD\IMZ\Photo\PhotoAddSuccessAD\"
        $log +="Обновление фото в AD: Файл "+(Get-JiraIssueAttachment -Issue $sph).filename+" добавлен в каталог \\npo\system$\1C-AD\IMZ\Photo\PhotoAddSuccessAD\ `r`n"
    }
    if ($desc -like $mmz){
        #Get-JiraIssueAttachment -Issue $sph | Set-ImageSize -Destination $pathmmz -WidthPx 250 -HeightPx 375 -Verbose
        Get-JiraIssueAttachmentFile (Get-JiraIssueAttachment -Issue $sph) -Path $patmmz
        $pathmmz+"\"+(Get-JiraIssueAttachment -Issue $sph).filename | Set-ImageSize -Destination $pathmmz -WidthPx 250 -HeightPx 375 -Verbose
        $log +="Обновление фото на портале: Файл "+(Get-JiraIssueAttachment -Issue $sph).filename+" добавлен в каталог "+$pathmmz +"`r`n"
        Set-photoAD -file $pathmmz+"\"+(Get-JiraIssueAttachment -Issue $sph).filename -pathout "\\npo\system$\1C-AD\MMZ\Photo\PhotoAddSuccessAD\"
        $log +="Обновление фото в AD: Файл "+(Get-JiraIssueAttachment -Issue $sph).filename+" добавлен в каталог \\npo\system$\1C-AD\MMZ\Photo\PhotoAddSuccessAD `r`n"
    } 
}

#запись лога в файл

$log | Out-File "\\npo\system$\Photo\PhotoAddPortal\Log.txt" -Append -Encoding UTF8