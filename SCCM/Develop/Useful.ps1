Import-Module activedirectory


$CMSite = Get-PSDrive -PSProvider CMSite -ErrorAction Stop -ErrorVariable CurrentError
            $SiteCode = $CMSite.Name
            $SiteServer = $CMSite.SiteServer
            CD "$($SiteCode):"
            Write-Host "Successfully Connected to ConfigMgr Site $SiteCode"
            If ($ErrorLog){
                Add-Content "$(get-date -Format g): Successfully Connected to ConfigMgr Site $SiteCode" -Path $LogFile
            }