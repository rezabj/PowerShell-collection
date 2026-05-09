function Invoke-LinuxLikeTop
{
   <#
         .SYNOPSIS
         Linux top equivalent in PowerShell

         .DESCRIPTION
         Linux top equivalent in PowerShell

         .PARAMETER Column
         .

         .PARAMETER Number
         Number of processes to display

         .EXAMPLE
         PS C:\> Invoke-LinuxLikeTop
         Get the top 30 processes, sorted by memory consumtion (Defaults)

         .EXAMPLE
         PS C:\> Invoke-LinuxLikeTop -Column CPU -Number 10
         Get the top 10 processes, sorted by CPU usage

         .EXAMPLE
         PS C:\> Invoke-LinuxLikeTop -Sort Memory -Top 10
         Get the top 10 processes, sorted by memory consumtion

         .NOTES
         Source: https://superuser.com/a/1426271
         Posted by: Clay, modified by community.
         See post 'Timeline' for change history, License - CC BY-SA 4.0
   #>
   [CmdletBinding(ConfirmImpact = 'None')]
   param
   (
      [Parameter(ValueFromPipeline,
      ValueFromPipelineByPropertyName)]
      [ValidateSet('Name', 'ID', 'User', 'CPU', 'Memory', 'Description', 'Title', IgnoreCase = $true)]
      [Alias('c', 's', 'SortCol', 'sort')]
      [string]
      $Column = 'Memory',
      [Parameter(ValueFromPipeline,
      ValueFromPipelineByPropertyName)]
      [ValidateRange(1, 100)]
      [Alias('t', 'Top')]
      [int]
      $Number = 30
   )

   process
   {
      # Get process list with or without UserName depending on admin rights
      if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
      {
         [array]$ProcessAttributes = @('ID', 'Name', 'UserName', 'Description', 'MainWindowTitle')
         [bool]$IncludeUserName = $true
      }
      else
      {
         [array]$ProcessAttributes = @('ID', 'Name', 'Description', 'MainWindowTitle')
         [bool]$IncludeUserName = $false
      }
      [array]$ProcessList = (Get-Process -IncludeUserName:$IncludeUserName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object -Property $ProcessAttributes)
      if (!($ProcessList))
      {
         Write-Error -Exception 'Unable to fetch the process list' -Message 'The process list is empty, unable to continue' -Category ResourceUnavailable -TargetObject $ProcessList -ErrorAction Stop
         Exit 1
      }
      [array]$Result = (Get-Counter -Counter '\Process(*)\ID Process', '\Process(*)\% Processor Time', '\Process(*)\Working Set - Private' -ErrorAction SilentlyContinue | ForEach-Object -MemberName CounterSamples | Where-Object -Property InstanceName -NotIn -Value '_total', 'memory compression' | Group-Object -Property {
            $_.Path.Split('\\')[3]
         } | ForEach-Object -Process {
            $ProcessIndex = [array]::indexof($ProcessList.ID, [int]$_.Group[0].CookedValue)
            [pscustomobject]@{
               Name        = $_.Group[0].InstanceName
               ID          = $_.Group[0].CookedValue
               User        = $ProcessList.UserName[$ProcessIndex]
               CPU         = if ($_.Group[0].InstanceName -eq 'idle')
               {
                  try
                  {
                     $_.Group[1].CookedValue / ((Get-CimInstance -ClassName Win32_processor -Property NumberOfLogicalProcessors -ErrorAction SilentlyContinue).NumberOfLogicalProcessors)
                  }
                  catch
                  {
                     ''
                  }
               }
               else
               {
                  $_.Group[1].CookedValue
               }
               Memory      = $_.Group[2].CookedValue / 1KB
               Description = $ProcessList.Description[$ProcessIndex]
               Title       = $ProcessList.MainWindowTitle[$ProcessIndex]
            }
         } | Sort-Object -Descending -Property $Column | Select-Object -First $Number -Property @(
            'Name', 'ID', 'User', 
            @{
               n = 'CPU'
               e = {
                  ('{0:N1}%' -f $_.CPU)
               }
            }, 
            @{
               n = 'Memory'
               e = {
                  ('{0:N0} K' -f $_.Memory)
               }
            }, 
            'Description', 'Title'
      ))

      if (!($Result))
      {
         Write-Error -Exception 'Unable to fetch the results' -Message 'There is no result data, unable to continue' -Category InvalidData -TargetObject $ProcessList -ErrorAction Stop
         Exit 1
      }
   }

   end
   {
      ($Result | Format-Table -AutoSize)
      $ProcessAttributes = $null
      $IncludeUserName = $null
      $ProcessList = $null
   }
}
(Invoke-LinuxLikeTop)
