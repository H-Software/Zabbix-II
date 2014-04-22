
Param(
  [string]$item
)

if( $item -Like "tsms.db_used_db_space_mb"){
    $sql = "select USED_DB_SPACE_MB from db"
}
elseif ($item -Like "tsms.db_free_space_db"){
    $sql = "select FREE_SPACE_MB from db"
}
elseif ($item -Like "tsms.node_sessions_count"){
    $sql = "select count(*) from sessions where session_type='Node'"
}
elseif($item -Like "tsms.db_buffer_hit_ratio"){
    $sql = "select BUFF_HIT_RATIO from db"
}
elseif ($item -Like "tsms.log_used_space_mb"){
    $sql = "select USED_SPACE_MB from log"
}
elseif ($item -Like "tsms.log_free_space_mb"){
    $sql = "select FREE_SPACE_MB from log"
}
elseif ($item -Like "tsms.db_archlog_used_space_mb"){
    $sql = "select ARCHLOG_USED_FS_MB from log"
}
elseif ($item -Like "tsms.db_archlog_free_space_mb"){
    $sql = "select ARCHLOG_FREE_FS_MB from log"
}
elseif ($item -Like "tsms.missed_backups"){
    $sql = "q even * * ex=yes begind=-1 begint=06:00 endd=today endt=05:59"
}
elseif ($item -Like "tsms.performed_backups"){
    $sql = "q even * * ex=no begind=-1 begint=06:00 endd=today endt=05:59"
}
elseif ($item -Like "tsms.success_performed_backups"){
    $sql = "select count(*) from summary where activity like 'BACKUP' and TIMESTAMPDIFF(4,CHAR(current_timestamp-start_time)) <= 1440"
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
