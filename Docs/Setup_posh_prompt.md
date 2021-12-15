# Setup Windows Terminal

1. Install nerd fonts (Hack). All complitable.
https://github.com/ryanoasis/nerd-fonts

2. Install Windows Terminal

3. Configure Windows Terminal

3.1. Default terminal application: Windows Terminal
3.2. In Apperance: Show acrylic in tab row
3.3 In Defaults > Apperance text change font on Hack NF and Enable acrylic

4. Install PowerShell (Store)

5. In settings WT. Where json config
duplicate theme 'One Half Dark' to 'One Half Dark (modded)'
change background to #001B26
In Defaults > Apperance change color theme

6. Install Scoop 
iwr -useb get.scoop.sh | iex

scoop install curl sudo jq

7. Git
winget install -e --id Git.Git

8. VIM
scoop install neovim gcc

9. Make a user profile and set command aliases
mkdir .config/powershell
Copy already config
nvim $PROFILE.CurrentUserCurrentHost
. $env:USERPROFILE\.config\powershell\user_profile.ps1

10. Oh-my-posh

Install-Module -Name posh-git -Scope CurrentUser -Force

Install-Module -Name oh-my-posh -Scope CurrentUser -Force

Install-Module -Name Terminal-Icons -Repository PSGallery -Force

Install-Module -Name z -Force

Install-Module -Name PSReadline -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck

scoop install fzf
