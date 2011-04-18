# These are constants that can be used to format the dates outputted

# "11 September 2008"
Time::DATE_FORMATS[:full] = "%d %B %Y"

# "Thursday 11 September, 2008"
Time::DATE_FORMATS[:day_full] = "%A %d %B, %Y"

# "Thursday 11 September, 2008 13:19"
Time::DATE_FORMATS[:day_full_with_time] = "%A %d %B, %Y %H:%M"

# "2008-09-11"
Time::DATE_FORMATS[:sortable] = "%Y-%m-%d"