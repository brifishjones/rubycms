class SiteController < ApplicationController

  uses_tiny_mce(:options => {:mode => 'textareas',
    :editor_selector => "mceEditor",
    :theme => 'advanced',
    :plugins => %w{table,safari,contextmenu,paste},
    :theme_advanced_toolbar_location => 'top',
    :theme_advanced_toolbar_align => 'left',
    :relative_urls => false,
    :remove_script_host => true,
    :content_css => 'stylesheets/modern/screen.css',
    :extended_valid_elements => %w{a[name|href|target|title|onclick] img[class|src|border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name|ondragdrop] hr[class|width|size|noshade] font[face|size|color|style] span[class|align|style]},
    :init_instance_callback => 'tinyInitInstanceCallback',
    :handle_event_callback => 'tinyHandleEvent'  
  })

  before_filter :authorize, :except => :show

  layout :determine_layout

  def determine_layout
    if (params[:action] == "show" || params[:action] == "edit") && request.post?
      return RCMS_LAYOUT_DEFAULT if session[:layout] == nil
    elsif params[:action] == "show" || params[:action] == "edit"
      page = Page.find_page(params[:url].join("/"))
      if page != nil && page.layout != nil
        return page.layout.name
      else
        return RCMS_LAYOUT_DEFAULT
      end
    end
    return session[:layout]
  end

  def edit
    params[:url] = Array.new if params[:url] == nil  # params[:url] is empty array for home page not nil
    if request.post?
      fn = Filename.new(params[:filename])
      if !fn.unique && fn.name != params[:url].join("/")
        edit_refresh
        flash[:notice] = fn.name + " already exists and cannot be replaced."
        @message_submit = ""
      elsif get_privileges == true && session[:update_layout] != true
        create
      else
        edit_refresh
        @message_submit = ""
      end
      
    else

      @page = Page.find_page(params[:url].join("/"))
      return if @page == nil
    
      # editing only in Firefox
      if !(request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/Firefox/])
        flash[:notice] = "At this time editing is only supported with Firefox browsers." 
        redirect_to(session[:original_uri] || {:action => "index"})
      end
    
      if @page.filename_id == nil
        @filename = nil
      else
        @filename = Filename.find(@page.filename_id)
      end
      
      if @page.keyword_id == nil
        @keyword = nil
      else
        @keyword = Keyword.find(@page.keyword_id)
      end
      
      @page.breadcrumb = params[:url].last.titleize if !params[:url].empty? && (@page.breadcrumb == nil || @page.breadcrumb == '')
      @page.valid_from = @page.valid_from != nil ? @page.valid_from.strftime("%m/%d/%Y %I:%M %p") : @page.valid_from = ''
      @page.valid_to = @page.valid_to != nil ? @page.valid_to.strftime("%m/%d/%Y %I:%M %p") : @page.valid_to = ''
      
      Dir['app/controllers/rubycms/**/*.rb'].each do |i|
        c = i.sub(/^app\/controllers\/rubycms\//, "").sub(/(_controller)?\.rb$/, "").capitalize
        self.instance_variable_set("@#{c.downcase}", ActiveRecord::Base.const_get(c).edit(@page, params[:url], session)) if defined?(ActiveRecord::Base.const_get(c).edit)
      end
      @page.add_captions_when_editing(params[:url].join("/"))
    
      @message_submit = ""
      @newstype = nil
      @newsname = nil
    
    end
  
    session[:url] = params[:url].dup
    
  end

  def get_privileges
    return false if session[:username] == nil

    u = User.find(:first,
        :conditions => ["name = ?", session[:username]])
    if u != nil
      valid, @message_submit = u.privileged(params[:filename]['name'], params[:page]['published'])
      flash[:notice] = @message_submit if session[:update_layout] != true
      return valid
    end
    u = Localuser.find(:first,
        :conditions => ["name = ?", session[:username]])
    if u != nil
      valid, @message_submit = u.privileged(params[:filename]['name'], params[:page]['published'])
      flash[:notice] = @message_submit if session[:update_layout] != true
      return valid
    end
    # not found
    flash[:notice] = "You do not have permissions to publish or write " + params[:filename]['name']
    return false
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

  def show
    params[:url] = Array.new if params[:url] == nil  # params[:url] is empty array for home page not nil
    if request.request_uri =~ /^\/pageid\/\d+$/
      @page = Page.find(params[:url].join("/")) if Page.exists?(params[:url].join("/"))
      @version_list = Page.find(:all,
        :order => 'modified DESC',
        :conditions => ["filename_id = ?", @page.filename_id]) if @page != nil
      params[:url] = @page.filename.name.split("/") if @page != nil
    elsif request.request_uri =~ /^\/staging/
      self.authorize
      @page = Page.find_page(params[:url].join("/"))
    else
      @page = Page.find_published(params[:url].join("/")) 
    end
    return if @page == nil
    
    if @page.filename_id == nil
      @filename = nil
    else
      @filename = Filename.find(@page.filename_id)
    end
    
    if @page.keyword_id == nil
      @keyword = nil
    else
      @keyword = Keyword.find(@page.keyword_id)
    end
    
    valid_from = @page.valid_from != nil ? @page.valid_from.strftime("%m/%d/%Y %I:%M %p") : ''
    valid_to = @page.valid_to != nil ? @page.valid_to.strftime("%m/%d/%Y %I:%M %p") : ''
    
    # check for read access restriction
    if read_access(@filename.name) == false
      @read_access_error = true
      return
    end
    
    # check date/time range for page validity
    @page_valid_message = page_valid(valid_from, valid_to)
    return if @page_valid_message != '' && request.request_uri !~ /^\/staging/ && request.request_uri !~ /^\/pageid\/\d+$/
    
    @page.add_captions_to_images
    # hash tags may be present in main content that display headline lists, events, etc.
    # see controllers/application.rb
    process_hashes   
    
    Dir['app/controllers/rubycms/**/*.rb'].each do |i|
      c = i.sub(/^app\/controllers\/rubycms\//, "").sub(/(_controller)?\.rb$/, "").capitalize
      self.instance_variable_set("@#{c.downcase}", ActiveRecord::Base.const_get(c).show(@page["#{c.downcase}" + "_id"], @page["#{c.downcase}" + "info"])) if defined?(ActiveRecord::Base.const_get(c).show)
    end

    session[:original_uri] = request.request_uri
    session[:previous_uri] = nil
    session[:update_layout] = nil
  end

  def create
    
    @page = Page.new(params[:page])
    
    @filename = Filename.new(params[:filename])
    if @filename.unique
      @filename.save!
      funique = true
    else
      @filename = Filename.find(:first,
        :conditions => ["name = ?", @filename.name])
      @filename.save!
      funique = false
    end
    
    if params[:keyword] != nil && params[:keyword] != ''
      @keyword = Keyword.new(params[:keyword])
      if @keyword.unique
        @keyword.save!
      else
        @keyword = Keyword.find(:first,
          :conditions => ["list = ?", @keyword.list])
      end
    else
      @keyword = nil
    end
    
    u = User.new
    u.name = session[:username]
    if u.unique   
      u.save!
    else
      u = User.find(:first,
        :conditions => ["name = ?", u.name])
    end
    

    if params[:page][:valid_from] == ''
      @page.valid_from = nil
    else
      begin
        @page.valid_from = Time.parse(params[:page][:valid_from])
      rescue
        @page.valid_from = nil
      end
    end
    if params[:page][:valid_to] == ''
      @page.valid_to = nil
    else
      begin
        @page.valid_to = Time.parse(params[:page][:valid_to])
      rescue
        @page.valid_to = nil
      end
    end
    @page.valid_to = nil if @page.valid_from != nil && @page.valid_to != nil && @page.valid_to < @page.valid_from

    self.instance_variable_set("@#{"navigation"}", ActiveRecord::Base.const_get("Navigation").create(session))
    self.instance_variable_set("@#{"layout"}", ActiveRecord::Base.const_get("Layout").create(session))
    self.instance_variable_set("@#{"form"}", ActiveRecord::Base.const_get("Form").create(session))
    self.instance_variable_set("@#{"contact"}", ActiveRecord::Base.const_get("Contact").create(session))
    self.instance_variable_set("@#{"banner"}", ActiveRecord::Base.const_get("Banner").create(@filename.name, funique, params[:url].join("/"), session[:banner], MAX_BANNER))
    self.instance_variable_set("@#{"imageside"}", ActiveRecord::Base.const_get("Imageside").create(@filename.name, funique, params[:url].join("/"), session[:imageside], MAX_IMAGESIDE))
    self.instance_variable_set("@#{"gallery"}", ActiveRecord::Base.const_get("Gallery").create(@filename.name, funique, params[:url].join("/"), session[:gallery], MAX_GALLERY))
    self.instance_variable_set("@#{"imagetop"}", ActiveRecord::Base.const_get("Imagetop").create(@page, @filename, funique, params[:url], session))
    
    Dir['app/controllers/rubycms/**/*.rb'].each do |i|
      c = i.sub(/^app\/controllers\/rubycms\//, "").sub(/(_controller)?\.rb$/, "").capitalize
      self.instance_variable_set("@#{c.downcase}", ActiveRecord::Base.const_get(c).create(@filename.name, funique, params[:url].join("/"), session[":" + "#{c.downcase}"], ActiveRecord::Base.const_get("MAX_" + "#{c.upcase}"))) if defined?(ActiveRecord::Base.const_get(c).create)
    end
    
    self.instance_variable_set("@#{"image"}", ActiveRecord::Base.const_get("Image").create(@page, @filename, funique, params[:url], session))
    @page.content = @image["content"]
    self.instance_variable_set("@#{"fileupload"}", ActiveRecord::Base.const_get("Fileupload").create(@page, @filename, funique, params[:url], session))
    @page.content = @fileupload["content"]

    @page.clean_content_before_save
    @page.modified = Time.now
    @page.navigation_id = @navigation.default.id if @navigation.default != nil
    @page.filename_id = @filename.id
    @page.keyword_id = @keyword.id if @keyword != nil
    @page.layout_id = @layout.default.id if @layout.default != nil
    @page.breadcrumb = '' if params[:url].empty? || @page.breadcrumb == params[:url].last.titleize || funique
    @page.form_id = @form.default.id if @form.default != nil
    @page.imagetop_id = @imagetop["current"].id if @imagetop["current"] != nil
    @page.contact_id = @contact.default.id if @contact.default != nil
    @page.user_id = u.id
    @page.imageinfo = @image["info"]
    @page.imagetopinfo = @imagetop["info"]
    @page.bannerinfo = @banner["info"]
    @page.imagesideinfo = @imageside["info"]
    @page.galleryinfo = @gallery["info"]
    @page.save!
    redirect_to('/staging/' + @filename.name)

  end

  def edit_refresh
  # called to resest instance variables after a page edit has been posted
  # and user does not have write or publish privileges
  # or after layout has changed and edit info needs to be refreshed in the new layout
  
    @page = Page.find_page(params[:url].join("/"))
    @filename = @page.filename_id == nil ? nil : Filename.find(@page.filename_id)
    @keyword = @page.keyword_id == nil ? nil : Keyword.find(@page.keyword_id)
    
    #self.instance_variable_set("@#{"navigation"}", ActiveRecord::Base.const_get("Navigation").edit_refresh(@page["#{"navigation"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"imagetop"}", ActiveRecord::Base.const_get("Imagetop").edit_refresh(@page["#{"imagetop"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"contact"}", ActiveRecord::Base.const_get("Contact").edit_refresh(@page["#{"contact"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"banner"}", ActiveRecord::Base.const_get("Banner").edit_refresh(@page["#{"banner"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"imageside"}", ActiveRecord::Base.const_get("Imageside").edit_refresh(@page["#{"imageside"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"gallery"}", ActiveRecord::Base.const_get("Gallery").edit_refresh(@page["#{"gallery"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"form"}", ActiveRecord::Base.const_get("Form").edit_refresh(@page["#{"form"}" + "_id"], params[:url], session))
    #self.instance_variable_set("@#{"layout"}", ActiveRecord::Base.const_get("Layout").edit_refresh(@page["#{"layout"}" + "_id"], params[:url], session))

    Dir['app/controllers/rubycms/**/*.rb'].each do |i|
      c = i.sub(/^app\/controllers\/rubycms\//, "").sub(/(_controller)?\.rb$/, "").capitalize
      self.instance_variable_set("@#{c.downcase}", ActiveRecord::Base.const_get(c).edit_refresh(@page["#{c.downcase}" + "_id"], params[:url], session)) if defined?(ActiveRecord::Base.const_get(c).edit_refresh)
    end
    
    # want content from post not original page
    p = Page.new(params[:page])
    @page.content = p.content
    @page.title = p.title
    @page.breadcrumb = p.breadcrumb
    @page.published = p.published
    @page.valid_from = p.valid_from
    @page.valid_to = p.valid_to
    session[:update_layout] = nil

  end

  def page_valid(valid_from, valid_to)
  # determine if page has expired or is valid at a future date.
  # return the message to be displayed if not valid ('' if valid)
    valid_from = '' if valid_from == nil
    valid_to = '' if valid_to == nil
    return '' if valid_from == '' && valid_to == ''

    if valid_from == ''
      return 'Page expired: ' + valid_to if Time.now > Time.parse(valid_to)
    elsif valid_to == ''
      return 'Page will become active: ' + valid_from if Time.now < Time.parse(valid_from)
    end
    return ''
  end

  def read_access(filename)
  # test if a user has read access to the given filename
  # return either true or false

    return false if filename == nil
    
    # administrators have read access
    return true if Administrator.find(:first, :conditions => ["name = ?", session[:username]])
    
    # check ldap users
    u = User.find(:first,
        :conditions => ["name = ?", session[:username]])
    lu = Localuser.find(:first,
        :conditions => ["name = ?", session[:username]])
    valid = true
    privs = Privilege.find(:all)
    
    # first check for read access
    for p in privs do
      if filename =~ Regexp.new(p.regex) && (p.user_read_list != nil && p.user_read_list != "" || p.group_read_list != nil && p.group_read_list != "")
        if p.user_read_list != nil && p.user_read_list != ""
          valid = false
          p.user_read_list.split.each do |r|
            # read granted if user has read privileges
            return true if (r == "*" && session[:username] != nil) || (u != nil && u.id == r.to_i) || (lu != nil && lu.id == r.to_i)
          end
        end
        
        if p.group_read_list != nil && p.group_read_list != ""  
          valid = false
          p.group_read_list.split.each do |r|
            # read granted if user is member of group with read privileges
            return true if (r == "*" && session[:username] != nil) || (session[:username] != nil && User.member_of_ldap_group(session[:username], r))
          end
        end
      end
    end
    
    return true if valid == true
    
    # if user has publish or write access then read access will be granted
    for p in privs do
      if filename =~ Regexp.new(p.regex)
        [p.user_publish_list, p.user_write_list].each do |userlist|
          if userlist != nil && userlist != ''
            userlist.split.each do |r|
              # read granted if user has write, or publish privileges
              return true if (r == "*" && session[:username] != nil) || (u != nil && u.id == r.to_i) || (lu != nil && lu.id == r.to_i)
            end
          end
        end
        
        [p.group_publish_list, p.group_write_list].each do |grouplist|
          if grouplist != nil && grouplist != ''
            grouplist.split.each do |r|
              # read granted if user is member of group with write, or publish privileges
              return true if (r == "*" && session[:username] != nil) || (session[:username] != nil && User.member_of_ldap_group(session[:username], r))
            end
          end
        end
      end  
      
    end
    
    return false
  end
    
  def show_version_list
  # in staging mode, list previous versions of the current page
    @page = Page.find(params[:page]) 
    @filename = Filename.find(params[:filename]) 
    return if @page == nil || @filename == nil
   
    @version_list = Page.find(:all,
       :order => 'modified DESC',
       :conditions => ["filename_id = ?", @filename.id])
   
    render :update do |page|
      page.replace_html("staging-versions", :partial => "staging")
    end 
  end

  def hide_version_list
  # in staging mode, list previous versions of the current page
    @page = Page.find(params[:page]) 
    @filename = Filename.find(params[:filename]) 
    return if @page == nil || @filename == nil
    @version_list = "hide version list"
   
    render :update do |page|
      page.replace_html("staging-versions", :partial => "staging")
    end 
  end

  def make_version_current
  # makes a copy of a previously saved version the most current version
    p = (Page.find(params[:page]))
    @page = p.clone
    @page.modified = Time.now
    
    # for each module call method "make_info_current" if it exists
    Dir['app/controllers/rubycms/**/*.rb'].each do |i|
      c = i.sub(/^app\/controllers\/rubycms\//, "").sub(/(_controller)?\.rb$/, "").capitalize
      ActiveRecord::Base.const_get(c).make_info_current(@page) if defined?(ActiveRecord::Base.const_get(c).make_info_current)
    end 

    @page.save
   
    render :update do |page|
      page.redirect_to('/staging/' + @page.filename.name)
    end 
  end

  def update_rjs
  # called to refresh appropriate part of page after closing iframes rubycms_imagetop, rubycms_contact, rubycms_banner, rubycms_gallery, rubycms_filemanager, rubycms_layout, ...
    #flash[:notice] = params[:url]

    if params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(layout)/
      session[:update_layout] = true
      render :update do |page|
        # render javascript directly -- http://railsforum.com/viewtopic.php?id=1043
        # form[0] is google search form
        # trigger auto submit but don't save information
        #page << "document.forms[1].submit();" 
        page << "document.rcmsedit.submit();"
      end
      return
      
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(filemanager)/
      render :update do |page|
      # nothing to update when the image and document manager iframe is closed
      end
      return
  
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(\w+)/
      self.instance_variable_set("@#{$4}", ActiveRecord::Base.const_get("#{$4}".capitalize).update_rjs(session))
      render :update do |page|
        page.replace_html("#{$4}", :partial => "#{$4}")
      end
      return
      
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(imagetop)/
      #update_imagetop
      #@imagetop_url, @imagetop, @updating = Imagetop.update_rjs(session)
      self.instance_variable_set("@#{"imagetop"}", ActiveRecord::Base.const_get("Imagetop").update_rjs(session))
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(contact)/
      #@contact = {"url" => session[:url], "list" => session[:contact_list], "hide" => session[:contact_hide]}
      self.instance_variable_set("@#{"contact"}", ActiveRecord::Base.const_get("Contact").update_rjs(session))
      #self.instance_variable_set("@#{"contact"}", ActiveRecord::Base.const_get("Contact").update_rjs(session))
     
      #update_contacts
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(banner)/
      @banner = {"url" => session[:url]}
      @banner.default = session[:banner]
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(imageside)/
      #update_imageside
      #@imageside_url, @imageside_uploads = Imageside.update_rjs(session)
      self.instance_variable_set("@#{"imageside"}", ActiveRecord::Base.const_get("Imageside").update_rjs(session)) 
      
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(gallery)/
      @gallery = {"url" => session[:url]}
      @gallery.default = session[:gallery]
    elsif params[:url] =~ /^(http(s?):\/\/)?([\w\-\.:]+)\/rubycms\/(form)/
      update_form
      return  
    else
      render :update do |page|
      end
      return
    end
    
    render :update do |page|
        page.replace_html("#{$4}", :partial => "#{$4}")
    end
  end

  def update_form
  # called after rubycms_form iframe closes
    @form = {"url" => session[:url], "name" => session[:form]}
    render :update do |page|
      page.replace_html("form-main", :partial => "form")
    end
  end

  def update_layout
  # called after rubycms_layout iframe closes
  session[:update_layout] = true
      render :update do |page|
        # render javascript directly -- http://railsforum.com/viewtopic.php?id=1043
        # form[0] is google search form
        # trigger auto submit but don't save information
        page << "document.forms[1].submit();" 
        #page.redirect_to("/edit/" + session[:url].join('/').to_s)
      end
  end

  # provides auto complete mechanism for keywords by pre-populating entries from category table
  def auto_complete_for_keyword_list
    auto_complete_responder_for_keyword params[:keyword][:list]
  end

  def auto_complete_responder_for_keyword (value)
    @category = Category.find(:all, 
    :conditions => [ 'LOWER(name) LIKE ?',
    '%' + value.downcase + '%' ], 
    :order => 'LOWER(name) ASC',
    :limit => 8)
    render :inline => "<%= content_tag(:ul, @category.map{|fai| content_tag(:li, content_tag(:div, h(fai.name), :class => 'name'), :class => 'feac') }, :class => 'feacs') %>"
  end
  
  # provides auto complete mechanism for filename by pre-populating entries from filename table
  def auto_complete_for_filename_name
    auto_complete_responder_for_filename params[:filename][:name]
  end

  def auto_complete_responder_for_filename (value)
    value.gsub!(/^\//, "")
    @filename = Filename.find(:all, 
    :conditions => [ 'LOWER(name) LIKE ?',
    '%' + value.downcase + '%' ], 
    :order => 'LOWER(name) ASC',
    :limit => 8)
    render :inline => "<%= content_tag(:ul, @filename.map{|fai| content_tag(:li, content_tag(:div, h(fai.name), :class => 'name'), :class => 'feac') }, :class => 'feacs') %>"
  end

end
