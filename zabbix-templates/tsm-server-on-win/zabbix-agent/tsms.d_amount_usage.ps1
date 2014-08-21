
Param(
  [string]$item,
  [string]$entityname
)

if( $item -Like "tsms.d_amount_discovery"){
    #$sql = "select node_name, sum(PHYSICAL_MB) from occupancy group by node_name"
    $sql = "select ENTITY from summary where activity='BACKUP' and TIMESTAMPDIFF(4,CHAR(current_timestamp-start_time)) <= 1440 group by entity"
}
elseif ($item -Like "tsms.d_amount_usage"){
    $sql = "select sum(BYTES) from summary where activity='BACKUP' and TIMESTAMPDIFF(4,CHAR(current_timestamp-start_time)) <= 1440 and ENTITY = '$entityname'"
}

$command = "C:\Program files\Tivoli\TSM\server\tsmdiag\dsmadmc.exe"
$params = "-id=monitor -pa=monpass -comma -dataonly=yes `"" + $sql + "`" "

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
  
  #
  # parse / or print results
  # 
  
  if($item -Like "tsms.d_amount_usage"){

     if($output.length -le 2){
	echo "0"
     }
     else{
	echo $output
     }

  }
  else{
    

    $rows = $output -split "\s+`n"

    echo "{`n`t`"data`":["
      
    for($i=0; $i -lt $rows.length; $i++) {
     
      $items = $rows[$i] -split "," 
      $name = $items[0]
    
      if ( $name.length -gt 0){
        echo "`t`t{ "
        echo "`t`t`t`"{#ENTITYNAME}`":`"$name`"}," 
      }
    }

    echo "`t`t]`n}"
  
    #  debug (all output)
    #  echo "- - - - - -"    
    #  echo $output

  }
  
  
}

