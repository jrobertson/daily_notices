# Creating a feed using the daily_notices gem

## Usage

    require 'daily_notices'

    notices = DailyNotices.new '/tmp/feed', url_base: 'http://www.jamesrobertson.eu/', \
    dx_xslt: '/xsl/dynarex-b.xsl', rss_xslt: '/xsl/feed.xsl'
    notices.add item: {title: 'testing something 123'}

The above snippet creates a directory called *feed* in the */tmp* file directory. In that subdirectory is a feed.xml which contains the most recent entries. Entries older than a day are archived in the *archive* directory, organised by year, month, and day.

## Resources

* daily_notices https://rubygems.org/gems/daily_notices

dailynotices notices feed rss
