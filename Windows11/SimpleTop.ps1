While (1) 
{
   Get-Process | Sort-Object -Descending -Property cpu | Select-Object -First 30
   Start-Sleep -Seconds 2
   Clear-Host
   Write-Output -InputObject 'Handles  NPM(K)    PM(K)      WS(K) VM(M)   CPU(s)     Id ProcessName'
   Write-Output -InputObject '-------  ------    -----      ----- -----   ------     -- -----------'
}
