
Param(
  [string]$item,
  [string]$var
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
elseif ($item -Like "tsms.query_status"){
    $sql = "query status"
}

$command = "C:\Program files\Tivoli\TSM\server\tsmdiag\dsmadmc.exe"
if($item -Like "tsms.query_status"){
  $params = "-id=monitor -pa=monpass -comma -dataonly=yes `"" + $sql + "`" "
}
else{
  $params = "-id=monitor -pa=monpass -tab -dataonly=yes `"" + $sql + "`" "
}

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

  if($item -Like "tsms.query_status"){

	$OutputArr = $output.Split(",");

        if($var -Like "Availability"){
	  $key = 16
	}
	else{
	  echo ZBX_NOTSUPPORTED
	  exit 1
	}

	if($outputArr[16] -eq "Enabled"){
	  echo 1
	}
	else{
	  echo 0
	}

  }
  else{
  	echo $output
  }

}

