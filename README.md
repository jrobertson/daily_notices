# Introducing the daily_notices gem

    require 'daily_notices'

    notices = DailyNotices.new '/tmp/feed', url_base: 'http://www.jamesrobertson.eu/', \
    dx_xslt: '/xsl/dynarex-b.xsl', rss_xslt: '/xsl/feed.xsl'
    notices.add 'testing something 123'

The above code would create a new RSS file called *rss.xml* in the */tmp/feed* directory. Along with that is the generated web page which is associated with the RSS item link. The link in this example would be *http://www.jamesrobertson.eu/feed/2015/oct/27/#132122*.

Here's the contents of the *rss.xml* file for the above example:

<pre>
&lt;?xml version='1.0' encoding='UTF-8'?&gt;
&lt;?xml-stylsheet title='XSL_formatting' type='text/xsl' href='/xsl/feed.xsl'?&gt;
&lt;rss version='2.0'&gt;
  &lt;channel&gt;
    &lt;title&gt;Daily notices&lt;/title&gt;
    &lt;description&gt;Generated using the daily_notices gem&lt;/description&gt;
    &lt;link&gt;http://www.jamesrobertson.eu/&lt;/link&gt;
    &lt;item&gt;
      &lt;title&gt;testing something 123&lt;/title&gt;
      &lt;description&gt;testing something 123&lt;/description&gt;
      &lt;link&gt;http://www.jamesrobertson.eu/feed/2015/oct/27/#132122&lt;/link&gt;
      &lt;pubDate&gt;Tue, 27 Oct 2015 13:21:22 +0000&lt;/pubDate&gt;
    &lt;/item&gt;
  &lt;/channel&gt;
&lt;/rss&gt;
</pre>

I observed that there were 2 files created in the file directory */tmp/feed/2015/oct/27/* called *index.xml* and *index.html*.

## Resources

* daily_notices https://rubygems.org/gems/daily_notices

dailynotices notices
