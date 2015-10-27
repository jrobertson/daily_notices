#!/usr/bin/env ruby

# file: daily_notices.rb


require 'rss_creator'
require 'fileutils'


class DailyNotices
  
  attr_accessor :title, :description, :link, :dx_xslt, :rss_xslt

  def initialize(filepath='', url_base: 'http:/127.0.0.1/', \
                                            dx_xslt: '', rss_xslt: '')
    
    @filepath, @url_base, @dx_xslt, @rss_xslt = filepath, \
                                                    url_base, dx_xslt, rss_xslt
        
    @archive_path = Time.now.strftime("%Y/%b/%d").downcase
    
    # If the file doesn't already exist in the 
    #                    archive directory then symlink it
    @indexpath = File.join(@filepath, @archive_path, 'index.xml')
    FileUtils.mkdir_p File.dirname(@indexpath)
    
    if File.exists? @indexpath then
      @dx = Dynarex.new @indexpath
    else
      @dx = Dynarex.new 'items/item(description, time)'
      @dx.order = 'descending'
      @dx.default_key = 'uid'
      @dx.xslt = @dx_xslt
    end
    
    # open the Dynarex file or create a new Dynarex file

    @rssfile = File.join(@filepath, 'rss.xml')
    
    if File.exists? @rssfile then
      @rss = RSScreator.new @rssfile
    else
      @rss = RSScreator.new
      @rss.xslt = @rss_xslt
      @rss.title = 'Daily notices'
      @rss.description = 'Generated using the daily_notices gem'      
      @rss.link = @url_base
    end    
  end
  
  def create(description, time=Time.now, title: nil, \
                                id: Time.now.strftime('%H%M%S'))

    @dx.create description: description, time: time, id: id   
    @dx.save @indexpath
    File.write  File.join(@filepath, @archive_path, 'index.html'), \
                                                  @dx.to_html(domain: @url_base)
    
    # Add it to the RSS document
    title ||= description.split(/\n/,2).first[0..140]
    link = File.join(@url_base, @archive_path, '#' + id)
    @rss.add title: title, link: link, description: description
    @rss.save @rssfile


  end
  
  alias add create

end