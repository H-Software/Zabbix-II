# Algorithm based on following lseventlog output format:
#
# sequence_number last_timestamp object_type object_id object_name         copy_id status fixed event_id error_code description
#
# Column width is data depend and must be calculated on every lseventlog invocation

{
  if (!errorcode_pos) {
    #first line
    #get position of "error_code" field from first line
    errorcode_pos = index($0, "error_code");
    descr_pos = index($0, "description");
    # calculate "error_code" field length (minus space)
    errorcode_len = descr_pos - errorcode_pos - 1
  } else {
    #other lines
    if (trim(substr($0, errorcode_pos, errorcode_len))) {
        print $0
    }
  }
}

function trim(s) {
  _strim = s;
  gsub(/ +$/,"", _strim);
  gsub(/^ +/,"", _strim);
  return _strim;
}


