#!/usr/bin/env ruby

# file: daily_notices.rb


require 'dx_sliml'
require 'rx_sliml'
require 'rss_creator'
require 'rxfreadwrite'


class DailyNotices
  include RXFReadWriteModule

  attr_accessor :title, :description, :link, :dx_xslt, :rss_xslt

  def initialize(filepath='', url_base: 'http:/127.0.0.1/', identifier: '',
                        dx_xslt: '', rss_xslt: '', target_page: :recordset,
                        target_xslt: '', title: 'daily notices', log: nil,
                        debug: false)

    @filepath, @url_base, @dx_xslt, @rss_xslt, @target_page, @target_xslt,  \
          @identifier, @log, @debug = filepath, url_base, dx_xslt, rss_xslt, \
          target_page, target_xslt, identifier, log, debug


    # note: card is intended for storing meta data in JSON format

    @schema = 'items[title, identifier, image, bio, location, website,' +
        ' banner_image]/item(title, description, card, time, link)'
    @default_key = 'uid'

    if dx_xslt.nil? then

      subdir = File.basename filepath
      dir = url_base[/http:\/\/[^\/]+\/(.*)/,1]

      dxxsltfilename = "dx#{Time.now.to_i.to_s}.xsl"
      dxxsltfilepath = '/' + [dir, subdir, dxxsltfilename].join('/')
      FileX.write File.join(filepath, dxxsltfilename), \
                                             DxSliml.new(dx: @schema).to_xslt

      @dx_xslt = dxxsltfilepath
    end

    if rss_xslt.nil? then

      subdir = File.basename filepath
      dir = url_base[/http:\/\/[^\/]+\/(.*)/,1]

      rssxsltfilename = "rssx#{Time.now.to_i.to_s}.xsl"
      rssxsltfilepath = '/' + [dir, subdir, rssxsltfilename].join('/')
      FileX.write File.join(filepath, rssxsltfilename), \
                                             RssSliml.new().to_xslt

      @rss_xslt = rssxsltfilepath
    end

    @day = Time.now.day
    @title = title
    new_day()

    # open the Dynarex file or create a new Dynarex file

    @rssfile = File.join(@filepath, 'rss.xml')

    if FileX.exists? @rssfile then
      @rss = RSScreator.new @rssfile, dx_xslt: @rss_xslt,
          custom_fields: ['topic'], log: @log
    else

      @rss = RSScreator.new @rssfile, dx_xslt: @rss_xslt,
          custom_fields: ['topic'], log: @log

      @rss.xslt = @rss_xslt
      @rss.title = @title || identifier.capitalize + ' daily notices'
      @rss.description = 'Generated using the daily_notices gem'
      @rss.link = @url_base
    end

    # :recordset or : record
    @target_page = target_page
  end

  def create(id: Time.now.to_i.to_s,
            item: {time: Time.now.strftime('%H:%M %p - %d %b %Y'),
                   title: nil})

    @log.info 'daily_notices/create: item: ' + item.inspect if @log
    h = item

    new_day() if @day != Time.now.day

    if @dx.all.any? and
        @dx.all.first.description == CGI.unescape(h[:description].to_s) then

      return :duplicate

    end

    h[:link] ||= create_link(id)
    h[:title] ||= h[:description]
        .split(/\n/,2).first.gsub(/\<\/?\w+[^>]*>/,'')[0..140]
    h[:time] ||= Time.now.strftime('%H:%M %p · %b %d %Y')


    #@dx.create({description: description, time: time}, id: id)
    puts 'before @dx.create' if @debug
    @log.info 'daily_notices/create: before' if @log

    # deep clone the Hash object
    h3 = Marshal.load( Marshal.dump(h) )
    h[:card] = h[:card].to_json if h[:card] and h[:card].is_a? Hash

    @dx.create(h, id: id)
    @log.info 'daily_notices/create: after' if @log
    #puts 'after @dx.create' if @debug

    @dx.save @indexpath

    render_html_files(id)

    # Add it to the RSS document

    if h3[:card] and h3[:card].is_a? Hash then

      card = h3[:card]
      h2 = card[card.keys.first]

      content = case card.keys.first
      when :summary_large_image
       "\n<h1>%s</h1><p>%s</p>" % [h2[:title], h2[:desc]]
      end

      h3[:title] += h2[:title] if h3[:title].empty?
      h3[:description] += content

    end

    @log.debug 'daily_notices/create: h3: ' + h3.inspect if @log
    @rss.add(item: h3, id: id)
    @rss.save @rssfile
    # open up the RSS file and fill in the title and description fields

    on_add(@indexpath, id)

    return true

  end

  alias add create


  def delete(id)

    [@dx, @rss].each {|x| x.delete(id.to_s); x.save}

    archive_path = Time.at(id.to_i).strftime("%Y/%b/%-d").downcase
    indexpath = File.join(@filepath, archive_path, id.to_s)

    FileX.rm_rf indexpath

    id.to_s + ' deleted'

  end

  def description()
    @rss.description
  end

  def description=(val)
    @rss.description = val
  end

  def image=(val)
    image_url, target_url = val.split
    @rss.image_url = image_url
    @rss.image_target_url = target_url
  end

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


  # If you wish override this method or use it in block form to add a
  #  notifier, callback routine or webhook, whenever a new record is added.
  #
  def on_add(xmlpath, id)

    yield(xmlpath, id) if block_given?

  end

  def save()
    @rss.save @rssfile
  end

  def to_dx()
    Dynarex.new @dx.to_xml
  end

  private

  def create_link(id)
    [File.join(@url_base, File.basename(@filepath), 'status', id)].join('/')
  end

  # configures the target page (using a Dynarex document) for a new day
  #
  def new_day()

    puts 'inside new_day' if @debug

    @archive_path = Time.now.strftime("%Y/%b/%-d").downcase

    @indexpath = File.join(@filepath, @archive_path, 'index.xml')
    FileX.mkdir_p File.dirname(@indexpath)


    if FileX.exists? @indexpath then
      @dx = Dynarex.new @indexpath
    else

      puts 'creating a new dx file' if @debug
      @dx = Dynarex.new @schema, debug: @debug
      @dx.order = 'descending'
      @dx.default_key = @default_key
      @dx.xslt = @dx_xslt
      @dx.title = @title
      @dx.identifier = @identifier
    end

   end

  def render_html_files(id)

    puts 'inside render_html_files' if @debug

    if @target_page == :recordset then
      FileX.write  File.join(@filepath, @archive_path, 'index.html'), \
                                                 @dx.to_html(domain: @url_base)
    else

      target_path = File.join(@filepath, @archive_path, id, 'index.html')
      FileX.mkdir_p File.dirname(target_path)

      rx = @dx.find(id)

      puts 'rx: ' + rx.inspect if @debug
      kvx = rx.to_kvx

      yield kvx if block_given?
      puts 'before kvx.to_xml' if @debug
      puts 'kvx.to_xml : ' + kvx.to_xml.inspect
      puts 'before 2 kvx.to_xml' if @debug
      rxdoc = Rexle.new(kvx.to_xml)
      puts 'after kvx.to_xml' if @debug

      rxdoc.instructions  << ['xml-styelsheet',\
          "title='XSL_formatting' type='text/xsl' href='#{@target_xslt}'"]
      FileX.write target_path.sub(/\.html$/,'.xml', ), rxdoc.xml(pretty: true)

      unless FileX.exists? @target_xslt then

        FileX.write @target_xslt,
            RxSliml.new(fields: %i(description time)).to_xslt
      end

      FileX.write  target_path, rx.to_html(xslt: @target_xslt)

    end

  end

end
