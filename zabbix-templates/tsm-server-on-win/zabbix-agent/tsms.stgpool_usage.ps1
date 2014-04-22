
Param(
  [string]$item,
  [string]$poolname
)

if( $item -Like "tsms.stgpool_usage_discovery"){
    $sql = "select stgpool_name, EST_CAPACITY_MB, PCT_UTILIZED from stgpools"
}
elseif ($item -Like "tsms.stgpool_usage_cap"){
    $sql = "select EST_CAPACITY_MB*1024*1024 from stgpools WHERE stgpool_name = '$poolname'"
}
elseif ($item -Like "tsms.stgpool_usage_ut"){
    $sql = "select PCT_UTILIZED from stgpools WHERE stgpool_name = '$poolname'"
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
  
  if($item -Like "tsms.stgpool_usage_cap"){
        
     $output_rounded = [Math]::Round($output, 0)
     echo $output_rounded

  }
  elseif($item -Like "tsms.stgpool_usage_ut"){
    
    echo $output
  }
  else{
    

    $rows = $output -split "\s+`n"

    echo "{`n`t`"data`":["
      
    for($i=0; $i -lt $rows.length; $i++) {
     
      $items = $rows[$i] -split "," 
      $name = $items[0]
    
      if ( $name.length -gt 0){
        echo "`t`t{ "
        echo "`t`t`t`"{#POOLNAME}`":`"$name`"}," 
      }
    }

    echo "`t`t]`n}"
  
    #  debug (all output)
    #  echo "- - - - - -"    
    #  echo $output

  }
  
  
}
