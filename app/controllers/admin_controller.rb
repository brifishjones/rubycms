class AdminController < ApplicationController
  require 'fileutils'
  include FileUtils::Verbose

  before_filter :authorize
  before_filter :is_administrator

  layout RCMS_LAYOUT_DEFAULT

  def index
    @filenames = Filename.find(:all,
      :order => 'name' )
    @pages = []
    for filename in @filenames
      @pages << Page.find(:all,
        :conditions => ["filename_id = ?", filename.id],
        :order => 'modified DESC',
        :limit => 1)
    end
  end

  def privileges
    @privileges = Privilege.find(:all,
      :order => 'regex')
    @users = User.find(:all,
        :order => 'id')
  end
  
  def users
  # list of users who have access to the system drawn from either ldap or localuser
    @users = User.find(:all,
        :order => 'name')
    if request.post?
      # verify that username is valid
      username = params[:user][:name]
      ldap = Net::LDAP.new(:host => 'ldap.rubycms.org', :port => 389, :base => 'dc=rubycms,dc=org')
      filter = Net::LDAP::Filter.eq('uid', username)
      ui = username
      ldap.search(:filter => filter) {|entry| ui = entry.dn}
      if !ui.include?("uid=" + username + ",ou=People,dc=rubycms,dc=org") && !Localuser.find(:first, :conditions => ["name = ?", username])
        flash[:notice] = ui + ' is not a valid username.  Before being added to the user list, a user must first be created in either LDAP or localuser.'
        render(:action => "users")
      else 
        @usr = User.new(params[:user])
        if @usr.save
          flash[:notice] = @usr.name + ' successfully added.'
          redirect_to('/admin/users')
        else
          flash[:notice] = @usr.name + ' not saved.'
          render(:action => "users")
        end
      end
    end
  end

  def localusers
    @localusers = Localuser.find(:all,
        :order => 'name')
    if request.post?
        @usr = Localuser.new(params[:localuser])
        if @usr.save
          flash[:notice] = @usr.name + ' successfully added.'
          redirect_to('/admin/localusers')
        else
          flash[:notice] = @usr.name + ' not saved.'
          render(:action => "localusers")
        end
    end
  end
  
  def administrators
    @administrators = Administrator.find(:all,
      :order => 'name')
    # since name is encrypted in the database it will need to be sorted now by the decripted name
    #@administrators = @administrators.sort_by { |a| a[:name] }
        
    if request.post?
        u = User.new
        u.name = params[:administrator][:name]
        # is user listed in users?
        if u.exists_in_ldap || Localuser.find(:first, :conditions => ["name = ?", u.name])
          if u.unique && !u.save
            flash[:notice] = 'There was a problem making ' + u.name + ' an administrator.  Could not save user.'
            render(:action => "administrators")
            return
          end
        else
          flash[:notice] = 'An unknown user cannot be made an administrator.  A user must first be created in either LDAP or localuser.'
          redirect_to('/admin/administrators')
          return
        end
        
        # add user to administrators
        @usr = Administrator.new(params[:administrator])
        if !@usr.unique
          flash[:notice] = @usr.name + ' is already an admisistrator'
        elsif @usr.save
          flash[:notice] = @usr.name + ' successfully made an administrator'
          redirect_to('/admin/administrators')
        else
          flash[:notice] = 'There was a problem making ' + @usr.name + ' an administrator.'
          render(:action => "administrators")
        end
    end
  end

  def remove_administrator 
    a = Administrator.find(params[:id])
    if a != nil && a.name != "admin"
      flash[:notice] = a.name + ' removed as administrator.'
      Administrator.delete(a.id)
    end
    @administrators = Administrator.find(:all,
      :order => 'name')
    redirect_to('/admin/administrators')
  end

  def delete_localuser
    lu = Localuser.find(params[:id])
    if lu != nil && lu.name != "admin"
      # if local user has administrative privileges, then remove
      a = Administrator.find(:first,
        :conditions => ["name = ?", lu.name])
      Administrator.delete(a.id) if a != nil
      flash[:notice] = lu.name + ' deleted.' 
      Localuser.delete(lu.id)
    end
    @localusers = Localuser.find(:all,
      :order => 'name')
    redirect_to('/admin/localusers')
  end

  def categories
    @categories = Category.find(:all,
      :order => 'LOWER(name)')
    
    if request.post?
        c = Category.new
        c.name = params[:category][:name]
        
        # add keyword to category list
        @keyword = Category.new(params[:category])
        if !@keyword.unique
          flash[:notice] = @keyword.name + ' is already listed as a keyword'
        elsif @keyword.save
          flash[:notice] = @keyword.name + ' successfully added to category list'
          redirect_to('/admin/categories')
        else
          flash[:notice] = 'There was a problem adding ' + @keyword.name + ' to the category list.'
          render(:action => "categories")
        end
    end
  end

  def remove_category 
    c = Category.find(params[:id])
    if c != nil
      flash[:notice] = c.name + ' removed as category.'
      Category.delete(c.id)
    end
    @categories = Category.find(:all,
      :order => 'LOWER(name)')
    redirect_to('/admin/categories')
  end

  def filename
    if Filename.exists?(params[:id])
      @filename = Filename.find(params[:id])
      @pages = Page.find(:all,
        :conditions => ["filename_id = ?", @filename.id],
        :order => 'modified DESC')
    end
    if request.post?
      @fn = Filename.new(params[:filename])
      @fn.clean
      # verify that username is valid
      if @filename.name == @fn.name
        flash[:notice] = @fn.name + ' is the same name.'
        render(:action => "filename", :id => params[:id])
      elsif Filename.find(:first,
        :conditions => ["name = ?", @fn.name])
        flash[:notice] = @fn.name + ' is not unique.'
        render(:action => "filename", :id => params[:id]) 
      else
        @filename.name = @fn.name
        if @filename.save
          flash[:notice] = 'filename changed to: ' + @filename.name + '.'
          redirect_to('/admin')
        else
          flash[:notice] = 'Could not rename ' + @filename.name + '.'
          render(:action => "filename", :id => params[:id])
        end
      end
    end
  end

  def delete_filename
  # given a filename delete filename, all versions of the page, images, banners, ...
    if Filename.exists?(params[:id])
      @filename = Filename.find(params[:id])
      
      # delete images from database and remove all files from public/system/images
      img = Image.find(:first,
        :conditions => ["pathname = ?", @filename.name])
      if img != nil
        delete_files(img.attachment_options[:path_prefix].to_s + '/' + img.pathname)
        #Dir.delete(img.attachment_options[:path_prefix].to_s + '/' + img.pathname)
        Image.delete_all(["pathname = ?", @filename.name])
      end
      
      # delete uploaded documents from database and remove from public/system/files
      fi = Fileupload.find(:first,
        :conditions => ["pathname = ?", @filename.name])
      if fi != nil
        delete_files(fi.attachment_options[:path_prefix].to_s + '/' + fi.pathname)
        Fileupload.delete_all(["pathname = ?", @filename.name])
      end
      
      # delete top images from database and remove from public/system/imagetops
      itop = Imagetop.find(:first,
        :conditions => ["pathname = ?", @filename.name])
      if itop != nil
        delete_files(itop.attachment_options[:path_prefix].to_s + '/' + itop.pathname)
        Imagetop.delete_all(["pathname = ?", @filename.name])
      end
      
      # delete left banners from database and remove from public/system/banners
      bl = Banner.find(:first,
        :conditions => ["pathname = ?", @filename.name])
      if bl != nil
        delete_files(bl.attachment_options[:path_prefix].to_s + '/' + bl.pathname)
        Banner.delete_all(["pathname = ?", @filename.name])
      end
      
      # delete side images from database and remove from public/system/imagesides
      iside = Imageside.find(:first,
        :conditions => ["pathname = ?", @filename.name])
      if iside != nil
        delete_files(iside.attachment_options[:path_prefix].to_s + '/' + iside.pathname)
        Imageside.delete_all(["pathname = ?", @filename.name])
      end
      
      # delete gallery images from database and remove from public/system/galleries
      gal = Gallery.find(:first,
        :conditions => ["pathname = ?", @filename.name])
      if gal != nil
        delete_files(gal.attachment_options[:path_prefix].to_s + '/' + gal.pathname)
        Gallery.delete_all(["pathname = ?", @filename.name])
      end
      
      @pages = Page.find(:all,
        :conditions => ["filename_id = ?", @filename.id],
        :order => 'modified DESC')
        
      # make a list of navigation and contact ids used by pages before deleting the page
      navigation_ids = []
      contact_ids = []
      for p in @pages
        navigation_ids << p.navigation_id if p.navigation_id != nil
        contact_ids << p.contact_id if p.contact_id != nil
        Page.delete(p.id)
      end
      navigation_ids.uniq!
      contact_ids.uniq!
      
      # delete only those navigations and contacts not used by other pages
      navigation_ids.each do |i|
        p = Page.find(:first,
          :conditions => ["navigation_id = ?", i])
        Navigation.delete(i) if p == nil
      end
      contact_ids.each do |i|
        p = Page.find(:first,
          :conditions => ["contact_id = ?", i])
        Contact.delete(i) if p == nil
      end
      
      Filename.delete(params[:id])
    end
    
    redirect_to('/admin')
  end

  def toggle_publish
    if Page.exists?(params[:id])
      @filename = Filename.find(params[:id])
      @pages = Page.find(:all,
        :conditions => ["filename_id = ?", @filename.id],
        :order => 'modified DESC')
    end
  end

  def add_user
    u = User.new(params[:user])
    if u.unique   
      u.save
    else
      flash[:notice] = u.name + ' has already been entered.'
    end
  end

  def navglobal
  # set global and main navigation for the site
    nav = Navglobal.find(:all,
      :order => 'id')
    @globalnav = ""
    nav.each do |i|
      @globalnav << i.nameglobal + "\n" if i.nameglobal != nil && i.nameglobal != ""
      @globalnav << i.linkglobal + "\n" if i.linkglobal != nil && i.linkglobal != ""
    end
    
    @mainnav = ""
    nav.each do |i|
      @mainnav << i.namemain + "\n" if i.namemain != nil && i.namemain != ""
      @mainnav << i.linkmain + "\n" if i.linkmain != nil && i.linkmain != ""
    end
  end

  def update_navglobal
    # keep global navigation at the beginning of the table.
    # grow and shrink accordingly
    maxrows = 100
  
    #@globalnav = params[:gn].strip!
    #@mainnav = params[:mn].strip!
    globallist = params[:gn].strip.split(/\n/)
    mainlist = params[:mn].strip.split(/\n/)
    0.step(globallist.size - 1, 2) do |i|
      begin
        n = Navglobal.find(i / 2 + 1)
      rescue ActiveRecord::RecordNotFound
        n = Navglobal.new
        n.nameglobal = globallist[i]
        n.linkglobal = globallist[i + 1]
        n.save
      else
        Navglobal.update(i / 2 + 1, :nameglobal => globallist[i], :linkglobal => globallist[i + 1])
      end
    end
    # if the list has shrunk remove entries
    i = globallist.size / 2 + 1
    while i < maxrows
      begin
        n = Navglobal.find(i)
      rescue ActiveRecord::RecordNotFound
        i = maxrows
      else
        Navglobal.update(i, :nameglobal => nil, :linkglobal => nil)
      end
      i += 1
    end
    
    0.step(mainlist.size - 1, 2) do |i|
      begin
        n = Navglobal.find(i / 2 + 1)
      rescue ActiveRecord::RecordNotFound
        n = Navglobal.new
        n.namemain = mainlist[i]
        n.linkmain = mainlist[i + 1]
        n.save
      else
        Navglobal.update(i / 2 + 1, :namemain => mainlist[i], :linkmain => mainlist[i + 1])
      end
    end
    # if the list has shrunk remove entries
    i = mainlist.size / 2 + 1
    while i < maxrows
      begin
        n = Navglobal.find(i)
      rescue ActiveRecord::RecordNotFound
        i = maxrows
      else
        Navglobal.update(i, :namemain => nil, :linkmain => nil)
      end
      i += 1
    end
    
    self.navglobal
    
    render :update do |page|
      page.replace_html("navgl", :partial => "navglobal")
    end
  end
  
  def refresh_navglobal
    @globalnav = params[:globalnav]
    @mainnav = params[:mainnav]
    
    render :update do |page|
      page.replace_html("navgl", :partial => "navglobal")
    end
  end

  def update_privileges
    @cur_regex = params[:cur_regex]
    if @cur_regex != nil
      @cur_regex = Privilege.find(@cur_regex)
    end
    # don't allow modification to another privilege definition
    if (@cur_regex != nil && @cur_regex.regex != params[:regex]) || @cur_regex == nil
      p = Privilege.find(:first,
        :conditions => ["regex = ?", params[:regex]])
      if p != nil
        flash[:notice] = "Regular expression exists in another privilege definition."
        @privileges = Privilege.find(:all,
          :order => 'regex')
        @users = User.find(:all,
          :order => 'id')
        return
      end
    end
    # no empty regular expressions
    if (params[:regex].blank?)
      flash[:notice] = "Regular expression cannot be blank."
      @privileges = Privilege.find(:all,
        :order => 'regex')
      @users = User.find(:all,
        :order => 'id')
      return
    end
    # check for invalid regular expression syntax
    begin
      Regexp.new(params[:regex])
    rescue
      flash[:notice] = "Regular expression has invalid syntax.  Please correct."
      @privileges = Privilege.find(:all,
        :order => 'regex')
      @users = User.find(:all,
        :order => 'id')
      return
    end
    
    if @cur_regex == nil
      @cur_regex = Privilege.new
    end
    @cur_regex.regex = params[:regex]
    
    upl = params[:user_publish_list].gsub(/\s*\,\s*/, ",").split(',').uniq
    gpl = params[:group_publish_list].gsub(/\s*\,\s*/, ",").split(',').uniq
    uwl = params[:user_write_list].gsub(/\s*\,\s*/, ",").split(',').uniq
    gwl = params[:group_write_list].gsub(/\s*\,\s*/, ",").split(',').uniq
    url = params[:user_read_list].gsub(/\s*\,\s*/, ",").split(',').uniq
    grl = params[:group_read_list].gsub(/\s*\,\s*/, ",").split(',').uniq
    
    
    # Remove any writers that are also publishers
    upl.each do |i|
      uwl.delete(i) if uwl.include?(i)
    end
    gpl.each do |i|
      gwl.delete(i) if gwl.include?(i)
    end
    # Remove any readers that are also publishers
    upl.each do |i|
      url.delete(i) if url.include?(i)
    end
    gpl.each do |i|
      grl.delete(i) if grl.include?(i)
    end
    
    # Create user publish list (ids) given username
    @cur_regex.user_publish_list = upl == [] ? nil : ""
    upl.each do |i|
      if i == "*"  # all users
        @cur_regex.user_publish_list << " " if @cur_regex.user_publish_list != ""
        @cur_regex.user_publish_list << "*"
      else
        u = User.find(:first,
          :conditions => ["name = ?", i])
        if u == nil
          u = User.new
          u.name = i
          if u.exists_in_ldap || Localuser.find(:first, :conditions => ["name = ?", u.name])
            u.save
            @cur_regex.user_publish_list << " " if @cur_regex.user_publish_list != ""
            @cur_regex.user_publish_list << u.id.to_s
          end
        else
          @cur_regex.user_publish_list << " " if @cur_regex.user_publish_list != ""
          @cur_regex.user_publish_list << u.id.to_s
        end
      end
    end
    
    # Create group publish list (names)
    @cur_regex.group_publish_list = gpl == [] ? nil : ""
    gpl.each do |i|
      if User.new.group_exists_in_ldap(i) 
        @cur_regex.group_publish_list << " " if @cur_regex.group_publish_list != ""
        @cur_regex.group_publish_list << i
      end
    end
    
    # Create user write list (ids) given username
    @cur_regex.user_write_list = uwl == [] ? nil : ""
    uwl.each do |i|
      if i == "*"  # all users
        @cur_regex.user_write_list << " " if @cur_regex.user_write_list != ""
        @cur_regex.user_write_list << "*"
      else
        u = User.find(:first,
          :conditions => ["name = ?", i])
        if u == nil
          u = User.new
          u.name = i
          if u.exists_in_ldap || Localuser.find(:first, :conditions => ["name = ?", u.name])
            u.save
            @cur_regex.user_write_list << " " if @cur_regex.user_write_list != ""
            @cur_regex.user_write_list << u.id.to_s
          end
        else
          @cur_regex.user_write_list << " " if @cur_regex.user_write_list != ""
          @cur_regex.user_write_list << u.id.to_s
        end
      end
    end
    
    # Create group write list (names)
    @cur_regex.group_write_list = gwl == [] ? nil : ""
    gwl.each do |i|
      if User.new.group_exists_in_ldap(i) 
        @cur_regex.group_write_list << " " if @cur_regex.group_write_list != ""
        @cur_regex.group_write_list << i
      end
    end
    
    # Create user read list (ids) given username
    @cur_regex.user_read_list = url == [] ? nil : ""
    url.each do |i|
      if i == "*"  # all users
        @cur_regex.user_read_list << " " if @cur_regex.user_read_list != ""
        @cur_regex.user_read_list << "*"
      else
        u = User.find(:first,
          :conditions => ["name = ?", i])
        if u == nil
          u = User.new
          u.name = i
          if u.exists_in_ldap || Localuser.find(:first, :conditions => ["name = ?", u.name])
            u.save
            @cur_regex.user_read_list << " " if @cur_regex.user_read_list != ""
            @cur_regex.user_read_list << u.id.to_s
          end
        else
          @cur_regex.user_read_list << " " if @cur_regex.user_read_list != ""
          @cur_regex.user_read_list << u.id.to_s
        end
      end
    end
    
    # Create group read list (names)
    @cur_regex.group_read_list = grl == [] ? nil : ""
    @cur_regex.group_read_list = ""
    grl.each do |i|
      if User.new.group_exists_in_ldap(i)
        @cur_regex.group_read_list << " " if @cur_regex.group_read_list != ""
        @cur_regex.group_read_list << i
      end
    end
    
    @cur_regex.save!
    flash[:notice] = @cur_regex.regex + " updated."
    
    @privileges = Privilege.find(:all,
      :order => 'regex')
    @users = User.find(:all,
        :order => 'id')

    render :update do |page|
      page.replace_html("privs", :partial => "privileges")
    end
  end

  def refresh_privileges   
    @cur_regex = nil
    @privileges = Privilege.find(:all,
      :order => 'regex')
    @users = User.find(:all,
        :order => 'id')
    render :update do |page|
      page.replace_html("privs", :partial => "privileges")
    end
  end
  
  def delete_privilege
    @cur_regex = params[:cur_regex]
    Privilege.delete(@cur_regex) if @cur_regex != nil
    @cur_regex = nil
    @privileges = Privilege.find(:all,
      :order => 'regex')
    @users = User.find(:all,
        :order => 'id')
    render :update do |page|
      page.replace_html("privs", :partial => "privileges")
    end
  end

  def add_regex   
    @cur_regex = nil
    render :update do |page|
      page.replace_html("regexedit", :partial => "priv_edit")
    end
  end
  
  def edit_regex   
    @cur_regex = Privilege.find(params[:priv])
    # make lists of user ids
    upl = @cur_regex.user_publish_list != nil ? @cur_regex.user_publish_list.split : []
    uwl = @cur_regex.user_write_list != nil ? @cur_regex.user_write_list.split : []
    url = @cur_regex.user_read_list != nil ? @cur_regex.user_read_list.split : []
    upa = []
    uwa = []
    ura = []

    # translate those lists into names
    upl.each do |i|
      if i == "*"
        upa << "*"
      else
        begin
          u = User.find(i)
        rescue
        else
          upa << u.name
        end
      end
    end
    @cur_regex.user_publish_list = upa.sort.join(", ")
    
    uwl.each do |i|
      if i == "*"
        uwa << "*"
      else
        begin
          u = User.find(i)
        rescue
        else
          uwa << u.name
        end
      end
    end
    @cur_regex.user_write_list = uwa.sort.join(", ")
    
    url.each do |i|
      if i == "*"
        ura << "*"
      else
        begin
          u = User.find(i)
        rescue
        else
          ura << u.name
        end
      end
    end
    @cur_regex.user_read_list = ura.sort.join(", ")
    
    # make lists of group names
    @cur_regex.group_publish_list = @cur_regex.group_publish_list.split.sort.join(", ") if @cur_regex.group_publish_list != nil
    @cur_regex.group_write_list = @cur_regex.group_write_list.split.sort.join(", ") if @cur_regex.group_write_list != nil
    @cur_regex.group_read_list = @cur_regex.group_read_list.split.sort.join(", ") if @cur_regex.group_read_list != nil

    render :update do |page|
      page.replace_html("regexedit", :partial => "priv_edit")
    end
    
  end
  
  def list
    @pages = Page.find(:all,
      :order => 'filename_id, modified')
  end

  def remove_unused_filenames()
  # clean up routine.  Traverse filenames and if no page references the filename then remove it
    flash[:notice] = ""
    fn = Filename.find(:all)
    fn.each do |i|
      if !Page.find(:first, :conditions => ["filename_id = ?", i.id])
        i.destroy
        flash[:notice] += i.name + ' deleted.<br />'
      end
    end
    redirect_to('/admin')
  end

end
