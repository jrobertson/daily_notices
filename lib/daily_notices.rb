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
      @rss = RSScreator.new @rssfile, dx_xslt: @dx_xslt
    else
      @rss = RSScreator.new dx_xslt: @dx_xslt
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
    link = [File.join(@url_base, File.basename(@filepath), \
                                            @archive_path, '#' + id)].join('/')
    @rss.add title: title, link: link, description: description
    @rss.save @rssfile


  end
  
  alias add create
  
  def title()
    @rss.title
  end
  
  def title=(val)
    @rss.title = val
  end
  
  def link()
    @rss.link
  end
  
  def link=(val)
    @rss.link = val
  end
  
  def description()
    @rss.description
  end
  
  def description=(val)
    @rss.description = val
  end
  
end