# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def authorize
    unless session[:username] != nil
      session[:previous_uri] = request.request_uri
      flash[:notice] = "Please log in"
      redirect_to(:controller => "login", :action => "index")
    end
  end
  
  def is_administrator
    return if session[:username] != nil && Administrator.find(:first, :conditions => ["name = ?", session[:username]])
    flash[:notice] = "Administrative privileges denied."
    redirect_to(session[:original_uri] || {:action => "index"})
    
  end

  def get_upload_privileges
    # determines if a logged in user can publish or write a given filename.
    # if so, then the user can upload files to the server.
    return false if session[:username] == nil
    
    u = User.find(:first,
          :conditions => ["name = ?", session[:username]])
    if u != nil
      valid, message = u.privileged(params[:url].join("/"), '0')
      return valid
    end
    # not found
    return false
  end

  def delete_files(directory)
  # deletes all files in a directory then deletes the directory itself if no child directories exist
    empty = true
    Dir["#{directory}/*"].each do |file|
      empty = false; next if File.directory?(file)
      FileUtils.rm_f file
    end
    FileUtils.rm_rf directory if empty == true
  end

  def rubycms_headlines
  # replaces #rubycms_headlines in content with the following: 
    c = []
    filenames = Filename.find(:all,
      :order => 'updated_at DESC',
      :conditions => ["name like ?", "%news/%"])
    if filenames != []
      c << '<div class="headlines-list">'
      c << '<hr />'
      pages = []
      filenames.each do |i|
        p = Page.find(:all,
          :conditions => ["filename_id = ? and published = ?", i.id, true],
          :order => 'modified DESC')
        pages << p[0]
      end
      for i in 0..filenames.size - 1
        c << '<p>'
        c << '<a href="/' + filenames[i].name + '">' + pages[i].title + '</a>' if pages[i] != nil && @page.keyword_match(pages[i].keyword) &&
          pages[i].published && pages[i].page_valid(pages[i].valid_from, pages[i].valid_to) && read_access(filenames[i].name) == true
        c << '</p>'
      end
      c << '</div> <!-- class="headlines-list" -->'
    end
    return c.join
  end

  def rubycms_news
  # replaces #rubycms_news in content with the following: 
    c = []
    filenames = Filename.find(:all,
      :order => 'updated_at DESC',
      :conditions => ["name like ?", "%news/%"])
    if filenames != []
      c << '<ul class="news-list">'
      pages = []
      filenames.each do |i|
        p = Page.find(:all,
          :conditions => ["filename_id = ? and published = ?", i.id, true],
          :order => 'modified DESC')
        pages << p[0]
      end
      j = 0
      for i in 0..filenames.size - 1
        if pages[i] != nil && @page.keyword_match(pages[i].keyword) &&
          pages[i].published && pages[i].page_valid(pages[i].valid_from, pages[i].valid_to) && read_access(filenames[i].name) == true
          imgs = pages[i].content.scan(/(<a href="\S+" class="highslide" onclick="return hs.expand\(this\)">)(<img src="\S+_\w+Ex\.\w+" border="0"\s)(alt="(.*?)"\s+)?(title="Click to enlarge"\s?\/><\/a>)/)
          c << '<hr />'
          c << '<li class="news-item">'
          c << '<span><div class="figure">' + imgs[0][1] + '/></a></div></span>' if imgs[0] != nil
          c << '<div class="news-item-title">'
          c << '<a href="/' + filenames[i].name + '">' + pages[i].title + '</a>'
          c << '</div class="news-item-title">'
          c << '<div class="news-item-teaser">'

          pages[i].content.gsub!(/(<a href="\S+" class="highslide" onclick="return hs.expand\(this\)"><img src="\S+_\w+Ex\.\w+" border="0"\s)(alt="(.*?)"\s+)?(title="Click to enlarge"\s?\/><\/a>)/, '')#'<span><div class="figure" style="width: XiLU6h3xB7r4NyzVpx">' + '\1' + 'alt="XiLU6h3xB7r4NyzV" ' + '\4' + 'XiLU6h3xB7r4NyzV</div></span>')
    
          c << pages[i].content.gsub(/\s{2,}/, ' ').gsub(/(<[^p>]*>)/, "").slice(0..400).slice(/.*\s/).gsub(/<\s*p\s*>/, '').gsub(/<\s*\/\s*p\s*>/, '&nbsp;&bull;&nbsp;')
          c << '<a href="/' + filenames[i].name + '">&nbsp;Read more...</a>'
          
          
          c << '</div class="news-item-teaser">'
          c << '</li class="news-item">'
          j += 1
          break if j == 10
        end
        
      end
      c << '</ul> <!-- class="news-list" -->'
    end
    return c.join
  end

  def rubycms_people
  # replaces #rubycms_people in content with the following: 
    
  end
  def rubycms_events
  # replaces #rubycms_events in content with the following: 
    
  end
  
  def rubycms_list(s)
  # replaces #rubycms_list in content given a type (titles, or overviews), and a site-wide filename
    s.gsub!(/["']/, "")
    s.gsub!(/&gt;/, ">")
    i = s.scan(/\w+\s*=>\s*\w+/)

    # construct the hash given the string s
    h = {"type" => "titles", "filename" => @filename.name}
    i.each do |line|
      h[$1] = $2 if /^(\w+)\s*=>\s*(\w+)$/ =~ line 
    end
    if !h.has_key?("display")
      h["display"] = h["type"] == "titles" ? 100 : 20
    end
    h["description_length"] = 400 if !h.has_key?("description_length")
    
    c = []
    filenames = Filename.find(:all,
      :order => 'updated_at DESC',
      :conditions => ["name like ?", "%" + @filename.name + "/%"])
    if filenames != []
      c << '<div class="list-titles">' if h["type"] == "titles"
      c << '<hr />' if h["type"] == "titles"
      c << '<ul class="list-overviews">' if h["type"] == "overviews"
      pages = []
      filenames.each do |i|
        p = Page.find(:all,
          :conditions => ["filename_id = ? and published = ?", i.id, true],
          :order => 'modified DESC')
        pages << p[0]
      end

      j = 0
      for i in 0..filenames.size - 1
        if pages[i] != nil && @page.keyword_match(pages[i].keyword) &&
          pages[i].published && pages[i].page_valid(pages[i].valid_from, pages[i].valid_to) && read_access(filenames[i].name) == true
          if h["type"] == "titles"
            c << '<p>'
            c << '<a href="/' + filenames[i].name + '">' + pages[i].title + '</a>' if pages[i] != nil && @page.keyword_match(pages[i].keyword) &&
            pages[i].published && pages[i].page_valid(pages[i].valid_from, pages[i].valid_to) && read_access(filenames[i].name) == true
            c << '</p>'
          elsif h["type"] == "overviews"
            imgs = pages[i].content.scan(/(<a href="\S+">\s*)(<img src="\S+_\w+Ex\.\w+"\s*\/>)\s*<\/a>/)
            c << '<hr />'
            c << '<li class="overviews-item">'
            c << '<span><div class="figure">' + imgs[0][1] + '</div></span>' if imgs[0] != nil
            c << '<div class="overviews-item-title">'
            c << '<a href="/' + filenames[i].name + '">' + pages[i].title + '</a>'
            c << '</div class="overviews-item-title">'
            c << '<div class="overviews-item-teaser">'
  
            pages[i].content.gsub!(/<a href="\S+">\s*<img src="\S+_\w+Ex\.\w+"\s*\/>\s*<\/a>/, '')

            c << pages[i].content.gsub(/\s{2,}/, ' ').gsub(/(<[^p>]*>)/, "").slice(0..h["description_length"]).slice(/.*\s/).gsub(/<\s*p\s*>/, '').gsub(/<\s*\/\s*p\s*>/, '&nbsp;&bull;&nbsp;')
            c << '<a href="/' + filenames[i].name + '">&nbsp;Read more...</a>'
            
            c << '</div class="overviews-item-teaser">'
            c << '</li class="overviews-item">'
          end
          j += 1
          break if j == h["display"].to_i
        end        
      end
      c << '</ul> <!-- class="overviews-list" -->' if h["type"] == "overviews"
      c << '</div> <!-- class="titles-list" -->' if h["type"] == "titles"
    end
    return c.join
  end
  
  def rubycms_google_calendar(s)
  # replaces #rubycms_google_calendar in content given a user_id and magic_cookie
    # https://www.google.com/calendar/feeds/jonebr01%40luther.edu/private-bee07b40fa4e3cc52d8a83427f7be186/basic?fields=@gd:*,id,entry%28@gd:*,title,content%29&orderby=starttime&sortorder=ascending&singleevents=true&futureevents=true&prettyprint=true 
    # http://wiki.github.com/hpricot/hpricot/
    require 'hpricot'
    #require 'open-uri'
    require 'net/https'
    require 'uri'
   
    s.gsub!(/["']/, "")
    s.gsub!(/&gt;/, ">")
    #s.gsub!(/@/, "\@")
    i = s.scan(/\w+\s*=>\s*[\w@\.]+/)
    i = s.scan(/\w+\s*=>\s*\[?[\w@\.,\s]+\]?/) if i.length == 0
    return "" if i.length == 0

    # construct the hash given the string s
    h = {"user_id" => "", "magic_cookie" => "", "end_time" => false, "display" => 30}
    uid = []
    mcook = []
    i.each do |line|
      #h[$1] = $2 if /^(\w+)\s*=>\s*([\w@\.]+)$/ =~ line
      if /^(\w+)\s*=>\s*([\w@\.]+)$/ =~ line || /^(\w+)\s*=>\s*\[?([\w@\.,\s]+)\]?$/ =~ line
        h[$1] = $2
        uid = $2.split(',') if $1 == "user_id"
        mcook = $2.split(',') if $1 == "magic_cookie"
      end
      #h[$1] = true if $2 == "true"
      #h[$1] = false if $2 == "false"
    end
    
    return "" if h["user_id"] == "" || h["magic_cookie"] == "" || uid.length != mcook.length
    c = []
    title = []
    start_time = []
    end_time = []
    where = []
    description = []
    
    uid.each_index do |k|
      uid[k].gsub!(/@/ , "%40")
      url = "https://www.google.com/calendar/feeds/" + uid[k].strip + "/private-" + mcook[k].strip + "/basic?fields=@gd:*,id,entry[title,content]&orderby=starttime&sortorder=ascending&singleevents=true&futureevents=true&prettyprint=true"
      url.gsub!(/\[/, "%28")
      url.gsub!(/\]/, "%29")
      
      # workaround for https requests using hpricot
      # see http://notetoself.vrensk.com/2008/09/verified-https-in-ruby/
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"  # enable SSL/TLS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end    
      
      http.start {
        http.request_get(uri.path + '?' + uri.query) {|res|
          f = Hpricot(res.body)
          #c << uri.path
          #c << uri.query
          e = (f/"entry")
          
          sort_index = 0
          e.each do |i|
            if /When:\s+\w+\s+(\w+\s+\d+,\s+\d+)\s+(\d+:?\d?\d?)(\w+)\s+to\s+(\d+:?\d?\d?)(\w+)\s*$/ =~ i.to_s
              st = Time.parse($1 + ' ' + $2 + ' ' + $3)
              et = Time.parse($1 + ' ' + $4 + ' ' + $5)
            end
            while start_time.length > sort_index && st > start_time[sort_index]
              sort_index += 1  
            end
            start_time.insert(sort_index, st)
            end_time.insert(sort_index, et)
            title.insert(sort_index, /<title type\=\"html\">(.*?)<\/title>/ =~ i.to_s ? $1 : nil)
            where.insert(sort_index, /Where:\s+(.*?)\s*$/ =~ i.to_s ? $1 : nil)
            
            description.insert(sort_index, /Event Description:\s+(.*?)\s*$/ =~ i.to_s ? $1: nil)
            
          end      
        }      
      }
    end
    start_time.sort!
    title.each_index do |i|
      c << title[i] + '<br />' if title[i] != nil 
      c << start_time[i].strftime("%a %d %b %Y %I:%M %p")
      c << ' - ' + end_time[i].strftime("%I:%M %p") if h["end_time"] == true
      c << '<br />'
      c << where[i] + '<br />' if where[i] != nil
      c << description[i] + '<br />' if description[i] != nil
      c << '<br />'
      break if i + 1 == h["display"]
    end
    return c.join
    
  end

  def process_hashes
  # searches for #rubycms_news, #rubycms_people, #rubycms_events hashes and replaces with appropriate ruby code for a given list
    return if @page.content == nil
    
    @page.content.gsub!(/#rubycms_list\s*\{(.*?)\}/) {rubycms_list($1)} 
    
    @page.content.gsub!(/#rubycms_google_calendar\s*\{(.*?)\}/) {rubycms_google_calendar($1)}
   
    #i = self.content.scan(/<img src="(\S+_\w+Ex\.\w+)"/)
    #i.each do |j|
    
    #if params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(\w+)/
    #self.instance_variable_set("@#{$4}", ActiveRecord::Base.const_get("#{$4}".capitalize).update_rjs(session))
    #  render :update do |page|
    #    page.replace_html("#{$4}", :partial => "#{$4}")
    #  end
    #@page.content.gsub!(/#rubycms_list\s*(\(.*?\))/, rubycms_list())
    @page.content.gsub!(/#rubycms_headlines/, rubycms_headlines)
    @page.content.gsub!(/#rubycms_news/, rubycms_news)
  end

end
