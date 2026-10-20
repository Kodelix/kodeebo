# S303: Windows' Egypt Standard Time adjustment rules from 2022 on, and the offset day by day around 2026's transitions
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('Egypt Standard Time')
foreach ($r in $tz.GetAdjustmentRules()) {
  if ($r.DateEnd.Year -ge 2022) {
    $s = $r.DaylightTransitionStart; $e = $r.DaylightTransitionEnd
    '{0:yyyy-MM-dd}..{1:yyyy-MM-dd} start fixed={2} M{3} D{4} W{5} {6} {7:HH:mm} | end fixed={8} M{9} D{10} W{11} {12} {13:HH:mm} | delta {14}' -f `
      $r.DateStart, $r.DateEnd, $s.IsFixedDateRule, $s.Month, $s.Day, $s.Week, $s.DayOfWeek, $s.TimeOfDay, `
      $e.IsFixedDateRule, $e.Month, $e.Day, $e.Week, $e.DayOfWeek, $e.TimeOfDay, $r.DaylightDelta
  }
}
$prev = $null
for ($d = [DateTimeOffset]::Parse('2026-01-01T12:00:00Z'); $d -lt [DateTimeOffset]::Parse('2027-01-01T12:00:00Z'); $d = $d.AddHours(1)) {
  $o = $tz.GetUtcOffset($d).TotalHours
  if ($o -ne $prev) { 'transition at UTC {0:yyyy-MM-ddTHH:mm}Z -> UTC+{1}' -f $d.UtcDateTime, $o; $prev = $o }
}
