# Load Prompt config
function Get-ScriptDirectory { Split-Path $MyInvocation.ScriptName }
$PROMPT_CONFIG = Join-Path (Get-ScriptDirectory) ".\ilyak.omp.json"
oh-my-posh -init -shell pwsh -config $PROMPT_CONFIG | Invoke-Expression

Import-Module -Name Terminal-Icons

# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -PredictionSource History

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Env
$env:GIT_SSH = "C:\Windows\system32\OpenSSH\ssh.exe"

# Alias
Set-Alias -Name vim -Value nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias grep findstr                                                                                                                                      Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'                                                                                                        Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'                                                                                                                                                                                                                                                                  # Utilities                                                                                                                                                 function which ($command) {                                                                                                                                   Get-Command -Name $command -ErrorAction SilentlyContinue |                                                                                                    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue                                                                                        }
