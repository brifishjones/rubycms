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

  def process_hashes
  # searches for #rubycms_news, #rubycms_people, #rubycms_events hashes and replaces with appropriate ruby code for a given list
    return if @page.content == nil
    @page.content.gsub!(/#rubycms_headlines/, rubycms_headlines)
    @page.content.gsub!(/#rubycms_news/, rubycms_news)
  end

end
