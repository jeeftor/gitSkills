def timestamp_epoch:
  . as $value |
  if $value == null then
    null
  else
    try (
      ($value
        | sub("\\.[0-9]+"; "")
        | capture("^(?<year>[0-9]{4})-(?<month>[0-9]{2})-(?<day>[0-9]{2})T(?<hour>[0-9]{2}):(?<minute>[0-9]{2}):(?<second>[0-9]{2})(?<zone>Z|(?<sign>[+-])(?<zhour>[0-9]{2}):?(?<zminute>[0-9]{2}))$")
      ) as $date |
      ([($date.year | tonumber), (($date.month | tonumber) - 1), ($date.day | tonumber), ($date.hour | tonumber), ($date.minute | tonumber), ($date.second | tonumber), 0, 0] | mktime) as $base |
      if $date.zone == "Z" then
        $base
      else
        (($date.zhour | tonumber) * 3600 + ($date.zminute | tonumber) * 60) as $offset |
        if $date.sign == "+" then
          $base - $offset
        else
          $base + $offset
        end
      end
    ) catch null
  end;

def relative_age($now_epoch):
  (timestamp_epoch) as $epoch |
  if $epoch == null then
    null
  else
    (($now_epoch - $epoch) | floor) as $age |
    (if $age < 0 then 0 else $age end) as $seconds |
    if $seconds < 60 then
      "now"
    elif $seconds < 3600 then
      (($seconds / 60 | floor | tostring) + "m ago")
    elif $seconds < 86400 then
      (($seconds / 3600 | floor | tostring) + "h ago")
    elif $seconds < 2592000 then
      (($seconds / 86400 | floor | tostring) + "d ago")
    elif $seconds < 31536000 then
      (($seconds / 2592000 | floor | tostring) + "mo ago")
    else
      (($seconds / 31536000 | floor | tostring) + "y ago")
    end
  end;
