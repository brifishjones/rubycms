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
  # replaces #rubycms_google_calendar in content given a user_id and magic_cookie.  Note that public calendars still require a magic cookie
    # https://www.google.com/calendar/feeds/jonebr01%40luther.edu/private-123456abcdef/basic?fields=@gd:*,id,entry%28@gd:*,title,content%29&orderby=starttime&sortorder=ascending&singleevents=true&futureevents=true&prettyprint=true 
    # http://wiki.github.com/hpricot/hpricot/
    require 'hpricot'
    #require 'open-uri'
    require 'net/https'
    require 'uri'
    require 'cgi'  # used to decode html entities (like &#036; and &Eacute;)

    s.gsub!(/&gt;/, ">")
    s.gsub!(/\[(\S+,\s*)+\S+\]/) {|m| m.gsub!(/,/, "!044!")}  # replace , with !044! between [ ]
    s.gsub!(/date_format\s*=>\s*["'].*?["']/) {|m| m.gsub(/,/, '!c0Mma!')}
    s.gsub!(/time_format\s*=>\s*["'].*?["']/) {|m| m.gsub(/,/, '!c0Mma!')}
    s.gsub!(/(date_format\s*=>\s*)(["'].*?["'])/) {|m| $1 + $2.gsub(/\s/, '!sPaCE!')}
    s.gsub!(/(time_format\s*=>\s*)(["'].*?["'])/) {|m| $1 + $2.gsub(/\s/, '!sPaCE!')}
    s.gsub!(/["']/, "")
    i = s.scan(/\w+\s*=>\s*\[?[\w@#\-\+\.!:;%\s\(\)]+\]?/) #if i.length == 0
    return "" if i.length == 0

    # construct the hash given the string s
    h = {"user_id" => "", "magic_cookie" => "", "end_time" => false, "display" => 50, "date_format" => "%A, %d %B %Y", "time_format" => "%I:%M %p",
      "start_date" => "", "end_date" => ""}
    display_max = 1000
    uid = []
    mcook = []
    i.each do |line|
      if /^(\w+)\s*=>\s*\[?([\w@#\-\+\.!:;%\s\(\)]+)\]?$/ =~ line
        h[$1] = $2
        uid = $2.split('!044!') if $1 == "user_id"
        mcook = $2.split('!044!') if $1 == "magic_cookie"
      end
      h[$1] = true if $2 == "true"
      h[$1] = false if $2 == "false"
    end
    #return h.inspect
    
    return "" if h["user_id"] == "" || h["magic_cookie"] == "" || uid.length != mcook.length

    c = []
    title = []
    start_time = []
    end_time = []
    where = []
    description = []
    
    h["start_date"] = gdate(h["start_date"], false)
    h["end_date"] = gdate(h["end_date"], true) 
    h["date_format"].gsub!(/!c0Mma!/, ",")
    h["time_format"].gsub!(/!c0Mma!/, ",")
    h["date_format"].gsub!(/!sPaCE!/, " ")
    h["time_format"].gsub!(/!sPaCE!/, " ")
    
    uid.each_index do |k|
      uid[k].gsub!(/@/ , "%40")
      uid[k].gsub!(/#/ , "%23")
      if /^public$/ =~ mcook[k].strip.downcase
        mcook[k] = "/public"
      else
        mcook[k] = "/private-" + mcook[k].strip
      end
      url = "https://www.google.com/calendar/feeds/" + uid[k].strip + mcook[k] +
        "/basic?fields=@gd:*,id,entry[title,content]&orderby=starttime&sortorder=ascending&singleevents=true" +
        (h["start_date"] == "" && h["end_date"] == "" ? "&futureevents=true" : "") +
        (h["end_date"] == "" ? "&max-results=" + h["display"].to_s : "&max-results=" + display_max.to_s) +
        (h["start_date"] != "" ? "&start-min=" + h["start_date"] : "") + (h["end_date"] != "" ? "&start-max=" + h["end_date"] : "")
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
          c << uri.path + '<br />'
          c << uri.query + '<br />'
          c << h["start_date"] + '<br />'
          c << h["end_date"] + '<br />'
          e = (f/"entry")
          #c << e
          
          sort_index = 0
          e.each do |i|
            if /When:\s+\w+\s+(\w+\s+\d+,\s+\d+)\s+(\d+:?\d?\d?)(\w+)\s+to\s+(\d+:?\d?\d?)(\w+)\s*$/ =~ i.to_s
              st = Time.parse($1 + ' ' + $2 + ' ' + $3)
              et = Time.parse($1 + ' ' + $4 + ' ' + $5)
            elsif /When:\s+\w+\s+(\w+\s+\d+,\s+\d+).*?$/ =~ i.to_s  # no time given
              st = Time.parse($1)
              et = Time.parse($1 + ' 23:59:59')
            end
            while start_time.length > sort_index && st > start_time[sort_index]
              sort_index += 1  
            end
            start_time.insert(sort_index, st)
            end_time.insert(sort_index, et)
            title.insert(sort_index, /<title type\=\"html\">(.*?)<\/title>/ =~ i.to_s ? CGI.unescapeHTML($1) : nil)
            where.insert(sort_index, /Where:\s+(.*?)\s*$/ =~ i.to_s ? CGI.unescapeHTML($1) : nil) 
            description.insert(sort_index, /Event Description:\s+(.*?)\s*$/ =~ i.to_s ? CGI.unescapeHTML($1) : nil)   
          end      
        }      
      }
    end
    #start_time.sort!
    c << '<table class="google-calendar">'
    prev_date = Time.parse("1/1/1970")
    title.each_index do |i|
      if prev_date.day != start_time[i].day || prev_date.month != start_time[i].month || prev_date.year != start_time[i].year
        c << '<tr><td colspan=2 class="google-calendar-date">'
        c << start_time[i].strftime(h["date_format"])
        c << '</td></tr>'
      end
      
      c << '<tr><td class="google-calendar-time">'
      if start_time[i].hour == 0 && start_time[i].min == 0 && end_time[i].hour == 23 && end_time[i].min == 59 && end_time[i].sec == 59
        c << '&nbsp;'
      else
        c << start_time[i].strftime(h["time_format"])
        c << ' - ' + end_time[i].strftime(h["time_format"]) if h["end_time"] == true
      end
      c << '</td>'
      
      c << '<td class="google-calendar-title">'
      c << title[i]
      
      if where[i] != nil || description[i] != nil
        if where[i] != nil
          c << '<div class="google-calendar-where">'
          c << where[i]
          c << '</div class="google_calendar_where">'
        end
        if description[i] != nil
          c << '<div class="google-calendar-description">'
          c << description[i]
          c << '</div class="google-calendar-description">'
        end
      end
      
      c << '</td></tr>'
      prev_date = start_time[i]
      
      break if i + 1 == h["display"] && h["end_date"] == ""
    end
    
    c << '</table class="google-calendar">'
    return c.join
    
  end
  
  def gdate(s, is_end_date)
  # tweak google start or end date parameters
    if s =~ /^[\+\-]\d+$/
      t = Time.now.advance(:days => $&.to_i).to_date
    elsif s != ""
      t = Time.parse(s)
    end
    return "" if s == "" || t == ""
    
    t = is_end_date ? Time.parse(t.to_date.to_s + " 23:59:59") : Time.parse(t.to_date.to_s)
    return t.strftime("%Y-%m-%dT%H:%M:%S") #+ (t.gmt_offset / 3600).to_s + ":" + ("0" if t.gmt_offset % 3600 < 10) + (t.gmt_offset % 3600).to_s
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
