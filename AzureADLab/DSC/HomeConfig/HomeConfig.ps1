configuration HomeConfig 
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$filesUrl,
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $filesUrl"
  Import-DscResource -ModuleName xSystemSecurity -Name xIEEsc
  Import-DscResource -ModuleName PSDesiredStateConfiguration

  Node localhost 
  {
    WindowsFeature ADTools
    {
        Ensure = "Present" 
        Name = "RSAT-AD-Tools"
    }
    WindowsFeature ADAdminCenter
    {
        Ensure = "Present" 
        Name = "RSAT-AD-AdminCenter"
    }
    WindowsFeature ADDSTools
    {
        Ensure = "Present" 
        Name = "RSAT-ADDS-Tools"
    }
    WindowsFeature ADPowerShell
    {
        Ensure = "Present" 
        Name = "RSAT-AD-PowerShell"
    }
    WindowsFeature RSATDNS
    {
        Ensure = "Present" 
        Name = "RSAT-DNS-Server"
    }
    WindowsFeature RSATFileServices
    {
        Ensure = "Present" 
        Name = "RSAT-File-Services"
    }
    WindowsFeature GPMC
    {
        Ensure = "Present" 
        Name = "GPMC"
    }
    xIEEsc DisableIEEscAdmin
    {
        IsEnabled = $false
        UserRole  = "Administrators"
    }
    xIEEsc DisableIEEscUser
    {
        IsEnabled = $false
        UserRole  = "Users"
    }
    Group AddLocalAdminsGroup
    {
        GroupName='Administrators'   
        Ensure= 'Present'             
        MembersToInclude= "$DomainName\LocalAdmins"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
    }
    Script DisableFirewall
    {
        SetScript =  { 
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DisableFirewall] Running.."
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
        }
        GetScript =  { @{} }
        TestScript = { $false }
    }
    Script DownloadClassFiles
    {
        SetScript =  { 
            $file = $using:filesUrl + 'class.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\Class.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\class.zip
         }
    }
    Script DownloadBootstrapFiles
    {
        SetScript =  { 
            $file = $using:filesUrl + 'bootstrap.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadBootstrapFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\bootstrap.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\bootstrap.zip
         }
    }
    Archive UnzipClassFiles
    {
        Ensure = "Present"
        Destination = "C:\Class"
        Path = "C:\Windows\Temp\Class.zip"
        Force = $true
        DependsOn = "[Script]DownloadClassFiles"
    }
    
    Archive UnzipBootstrapFiles
    {
        Ensure = "Present"
        Destination = "C:\Bootstrap"
        Path = "C:\Windows\Temp\Bootstrap.zip"
        Force = $true
        DependsOn = "[Script]DownloadBootstrapFiles"
    }
    Script UpdateHelp
    {
        SetScript =  { 
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[UpdateHelp] Running.."
            Update-Help -Force
        }
        GetScript =  { @{} }
        TestScript = { $false }
    }
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}