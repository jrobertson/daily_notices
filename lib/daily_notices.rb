#!/usr/bin/env ruby

# file: daily_notices.rb


require 'dx_sliml'
require 'rx_sliml'
require 'fileutils'
require 'rss_creator'



class DailyNotices
  
  attr_accessor :title, :description, :link, :dx_xslt, :rss_xslt

  def initialize(filepath='', url_base: 'http:/127.0.0.1/', identifier: '', 
                        dx_xslt: '', rss_xslt: '', target_page: :recordset, 
                        target_xslt: '', title: 'daily notices')
    
    @filepath, @url_base, @dx_xslt, @rss_xslt, @target_page, @target_xslt,  \
          @identifier = filepath, url_base, dx_xslt, rss_xslt, target_page, \
          target_xslt, identifier

    
    @schema ||= 'items[title, identifier]/item(description, time)'
    @default_key ||= 'uid'
    
    if dx_xslt.nil? then

      subdir = File.basename filepath
      dir = url_base[/http:\/\/[^\/]+\/(.*)/,1]

      dxxsltfilename = "dx#{Time.now.to_i.to_s}.xsl"
      dxxsltfilepath = '/' + [dir, subdir, dxxsltfilename].join('/')      
      File.write File.join(filepath, dxxsltfilename), \
                                             DxSliml.new(dx: @schema).to_xslt
      
      @dx_xslt = dxxsltfilepath
    end
    
    if rss_xslt.nil? then

      subdir = File.basename filepath
      dir = url_base[/http:\/\/[^\/]+\/(.*)/,1]

      rssxsltfilename = "rssx#{Time.now.to_i.to_s}.xsl"
      rssxsltfilepath = '/' + [dir, subdir, rssxsltfilename].join('/')
      File.write File.join(filepath, rssxsltfilename), \
                                             RssSliml.new().to_xslt
      
      @rss_xslt = rssxsltfilepath
    end    
    
    @day = Time.now.day
    @title = title
    new_day()
    
    # open the Dynarex file or create a new Dynarex file

    @rssfile = File.join(@filepath, 'rss.xml')

    if File.exists? @rssfile then
      @rss = RSScreator.new @rssfile, dx_xslt: @rss_xslt, 
          custom_fields: ['topic']
    else

      @rss = RSScreator.new @rssfile, dx_xslt: @rss_xslt, 
          custom_fields: ['topic']
      @rss.xslt = @rss_xslt
      @rss.title = @title || identifier.capitalize + ' daily notices'
      @rss.description = 'Generated using the daily_notices gem'
      @rss.link = @url_base
    end    
    
    # :recordset or : record
    @target_page = target_page
  end
  
  def create(h={time: Time.now.strftime('%H:%M %p - %d %b %Y'), title: nil}, id: Time.now.to_i.to_s)

    
    new_day() if @day != Time.now.day

    if @dx.all.any? and 
        @dx.all.first.description == CGI.unescape(h[:description]) then

      return :duplicate

    end
        
    #@dx.create({description: description, time: time}, id: id)
    @dx.create(h, id: id)        
    @dx.save @indexpath
    
    if @target_page == :recordset then
      File.write  File.join(@filepath, @archive_path, 'index.html'), \
                                                 @dx.to_html(domain: @url_base)
    else

      target_path = File.join(@filepath, @archive_path, id, 'index.html')
      FileUtils.mkdir_p File.dirname(target_path)

      rx = @dx.find(id)

      kvx = rx.to_kvx
      yield kvx if block_given? 

      rxdoc = Rexle.new(kvx.to_xml)
      rxdoc.instructions  << ['xml-styelsheet',\
          "title='XSL_formatting' type='text/xsl' href='#{@target_xslt}'"]
      File.write target_path.sub(/\.html$/,'.xml', ), rxdoc.xml(pretty: true)
      
      unless File.exists? @target_xslt then
        File.write @target_xslt, 
            RxSliml.new(fields: %i(description time)).to_xslt 
      end
      
      File.write  target_path, rx.to_html(xslt: @target_xslt)

    end

    # Add it to the RSS document
    title ||= h[:description].split(/\n/,2).first[0..140]
    link = create_link(id)
    
    @rss.add( {title: title, link: link}.merge(h), id: id)
    @rss.save @rssfile
    
    on_add(@indexpath, id)
    
    return true

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
  
  # If you wish override this method or use it in block form to add a  
  #  notifier, callback routine or webhook, whenever a new record is added.
  #
  def on_add(xmlpath, id)
    
    yield(xmlpath, id) if block_given?
    
  end  
  
  def save()
    @rss.save @rssfile    
  end
  
  private 
  
  def create_link(id)
    [File.join(@url_base, File.basename(@filepath), 'status', id)].join('/')
  end
  
  # configures the target page (using a Dynarex document) for a new day
  #
  def new_day()
    
    @archive_path = Time.now.strftime("%Y/%b/%d").downcase
    
    @indexpath = File.join(@filepath, @archive_path, 'index.xml')
    FileUtils.mkdir_p File.dirname(@indexpath)
    
        
    if File.exists? @indexpath then
      @dx = Dynarex.new @indexpath
    else
      @dx = Dynarex.new @schema
      @dx.order = 'descending'
      @dx.default_key = @default_key
      @dx.xslt = @dx_xslt
      @dx.title = @title
      @dx.identifier = @identifier
    end    
    
  end
  
end