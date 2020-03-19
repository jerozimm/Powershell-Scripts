Function SCCMTimeFormat
{
param($hour = (get-date -format HH), $min = (get-date -format mm), $sec = (get-date -format ss), $date = (get-date))
get-date -hour $hour -minute $min -second $sec -day $date.day -month $date.month -year $date.year -format yyyyMMddHHmmss.000000+***
}
$Time            = (get-date “21/03/2013 9:00 AM”) #put your desired date/time here
$starttime       = (WMIDateFormat $Time.Hour $Time.Minute $Time.Second $Time.AddDays(0))
$starttime
