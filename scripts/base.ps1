$python_not_found = "Cannot find Python. Is Anaconda for Python 3.7 installed?"
$path1 = "Registry::HKEY_CURRENT_USER\Software\Python\ContinuumAnalytics\Anaconda37-64\InstallPath"
$path2 = "Registry::HKEY_LOCAL_MACHINE\Software\Python\ContinuumAnalytics\Anaconda37-64\InstallPath"
$value = "ExecutablePath"

# https://stackoverflow.com/questions/5648931
Function Test-RegistryValue {
    param(
            [Alias("PSPath")]
            [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [String]$Path
            ,
            [Parameter(Position = 1, Mandatory = $true)]
            [String]$Name
            ,
            [Switch]$PassThru
         ) 

        process {
            if (Test-Path $Path) {
                $Key = Get-Item -LiteralPath $Path
                    if ($Key.GetValue($Name, $null) -ne $null) {
                        if ($PassThru) {
                            Get-ItemProperty $Path $Name
                        } else {
                            $true
                        }
                    } else {
                        $false
                    }
            } else {
                $false
            }
        }
}
Function Run-Python {
    param(
            [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [String]$Cmd
         ) 
	process {
		
		if (Test-RegistryValue -Path $path1 -Name $value) {
				$p = (Test-RegistryValue -PassThru -Path $path1 -Name $value).$value
				iex "& $p $cmd"
		} elseif (Test-RegistryValue -Path $path2 -Name $value) {
				$p = (Test-RegistryValue -PassThru -Path $path2 -Name $value).$value
				iex "& $p $cmd"
		} else {
				Write-Error $python_not_found -ErrorAction Stop
		}
	}
}
Function Activate-Anaconda {
	process {
		if (Test-RegistryValue -Path $path1 -Name $value) {
				$p = (Test-RegistryValue -PassThru -Path $path1 -Name $value).$value
				$p = (Split-Path -Parent -Path $p)
				$env:Path = "$p;$p\Scripts;" + $env:Path
				activate.bat $p
		} elseif (Test-RegistryValue -Path $path2 -Name $value) {
				$p = (Test-RegistryValue -PassThru -Path $path2 -Name $value).$value
				$p = (Split-Path -Parent -Path $p)
				$env:Path = "$p;$p\Scripts;" + $env:Path
				activate.bat $p
		} else {
				Write-Error $python_not_found -ErrorAction Stop
		}
	}
}
