
Param(
  [string]$item
)

if( $item -Like "tsms.count_of_completed_backups"){
    $sql = "select count(*) from events where schedule_name like 'CS%' and TIMESTAMPDIFF(4,CHAR(current_timestamp-scheduled_start)) <= 1440 and status='Completed' "
}
elseif ($item -Like "tsms.count_of_failed_backups"){
    $sql = "select count(*) from events where schedule_name like 'CS%' and TIMESTAMPDIFF(4,CHAR(current_timestamp-scheduled_start)) <= 1440 and status like 'Failed%'"
}
elseif ($item -Like "tsms.count_of_missed_backups"){
    $sql = "select count(*) from events where schedule_name like 'CS%' and TIMESTAMPDIFF(4,CHAR(current_timestamp-scheduled_start)) <= 1440 and status='Missed'"
}

$command = "C:\Program files\Tivoli\TSM\server\tsmdiag\dsmadmc.exe"
$params = "-id=monitor -pa=monpass -tab -dataonly=yes `"" + $sql + "`" "

$timeout = "1000"

[Environment]::SetEnvironmentVariable("DSM_CONFIG", "C:\Progra~1\Tivoli\TSM\server\tsmdiag\dsm.opt", "User")
[Environment]::SetEnvironmentVariable("DSM_DIR", "C:\Progra~1\Tivoli\TSM\server\tsmdiag", "User")

Set-ExecutionPolicy Unrestricted

$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
$ProcessInfo.FileName = $command 
$ProcessInfo.RedirectStandardError = "true" 
$ProcessInfo.RedirectStandardOutput = "true"
$ProcessInfo.UseShellExecute = $false 

$ProcessInfo.Arguments = $params
$ProcessInfo.WorkingDirectory = $folder

$Process = New-Object System.Diagnostics.Process 
$Process.StartInfo = $ProcessInfo 
$Process.Start() | Out-Null 

$ProcessWait = $Process.WaitForExit($timeout) 

$output = $Process.StandardOutput.ReadToEnd()

if ( ! $ProcessWait ) { 
  echo "Program dsmadmc did not exit after 1000ms"; 
  echo $output
  $Process.kill() 
}
else {
  echo $output
}

