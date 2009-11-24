# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

def editing_page
  return true if ((params[:controller] == 'site' || params[:controller] == 'rubycms/navigation') && (params[:action] == 'edit' || params[:action] == 'set_to_edit_mode' ||
    params[:action] == 'order_navlist' || params[:action] == 'update_navlist' || params[:action] == 'add_to_navlist'|| 
    params[:action] == 'refresh_navlist' || params[:action] == 'replace_navlist' || params[:action] == 'delete_from_navlist' ||
    params[:action] == 'import_navlist' || params[:action] == 'revert_navlist' ||params[:action] == 'update_imagetop_image' || 
    params[:action] == 'update_contacts' || params[:action] == 'update_banners' || params[:action] == 'update_gallery' ||
    params[:action] == 'update_imageside' || params[:action] == 'update_form' || params[:action] == 'clear_form' ||
    params[:action] == 'update_layout' || params[:action] == 'clear_layout' ||
    params[:action] == 'update_rjs'))
  return false
end

def settitle
  t = '<title>'
  if params[:controller] != 'site'
    t << params[:controller].capitalize + ': ' + controller.action_name + ' - '
  else
    if params[:action] != 'show'
      t << params[:action].capitalize + ': '
    end
    if @page != nil && (@page.title != nil && @page.title != "")
     t << @page.title + ' - '
    end
  end 
  t << '</title>'
  return t
end

def highslideinit
# initialize highslide javascript image viewer -- http://highslide.com
  hs = []
  hs << '<script type="text/javascript" src="/javascripts/highslide/highslide-full.js">
     </script>'

  if params[:action] == 'edit'
    hs << '<script type="text/javascript">
      hs.graphicsDir = "/javascripts/highslide/graphics/";
      hs.outlineType = "rounded-white";
      hs.outlineWhileAnimating = true;
      hs.showCredits = false;
      hs.wrapperClassName = "draggable-header";
  
      hs.Expander.prototype.onBeforeClose = function (sender) {
      //alert (this.a.href);
        //new Ajax.Request("/site/update_rjs", {asynchronous:true, evalScripts:true, parameters: {url: sender.a}});
        new Ajax.Request("/site/update_rjs", {asynchronous:true, evalScripts:true, parameters: {url: sender.a.href}});
        return;
      };
    </script>'
    hs << stylesheet_link_tag("highslide", :media => "screen")
  else 
    hs << '<script type="text/javascript">
      
      hs.graphicsDir = "/javascripts/highslide/graphics/";
      hs.outlineType = "drop-shadow";
      hs.wrapperClassName = "wide-border";
      //hs.outlineWhileAnimating = true;
      hs.showCredits = false;
      hs.captionEval = "this.thumb.alt";
      
      hs.align = "center";
      hs.transitions = ["expand", "crossfade"];
      hs.transitionDuration = 1000;
      hs.fadeInOut = true;
      hs.marginBottom = 105; // make room for the thumbstrip and the controls

      // Add the slideshow providing the controlbar and the thumbstrip
      hs.addSlideshow({
      slideshowGroup: 1,
      interval: 5000,
      repeat: true,
      useControls: true,
      fixedControls: "fit",
      overlayOptions: {
        position: "bottom center",
        hideOnMouseOut: true
      },
      thumbstrip: {
        position: "bottom center",
        mode: "horizontal",
        relativeTo: "viewport"
      }
    });
    </script>'
    hs << stylesheet_link_tag("highslide", :media => "screen")
  end  #if params[:action] == 'edit'
  return hs
end

def iframeinit
  f = []
  # link to stylesheets used by each of the rubycms iframes (file, lay, gal, fm, ...) 
  Dir.glob("public/stylesheets/rubycms/[^_]*.css").each do |i| 
    f << stylesheet_link_tag(i.sub(/public\/stylesheets\//, ""), :media => "screen")
  end
  return f
end

def set_tiny_options
# sets the tinyMCE titlebar based on the chosen layout.
# looks for file called <layout>_helper.rb in app/helpers/layouts which contains @tiny_mce_options settings
# for the modern layout the appropriate file would be app/helpers/layouts/modern_helper.rb
  if using_tiny_mce?
    Dir.glob("app/views/layouts/*").each do |i|
      if File.directory?(i) && i.split('/').pop == session[:layout].split('/')[0]
        send("set_tiny_options_" + i.split('/').pop, session)
        return
      end
    end
    
    #default if file not found
    @tiny_mce_options["width"] = "100%"
    @tiny_mce_options["height"] = "560"
    @tiny_mce_options["theme_advanced_buttons1"] = %w{bold italic underline separator strikethrough justifyleft justifycenter justifyright justifyfull separator formatselect bullist numlist table undo redo link unlink code}
    @tiny_mce_options["theme_advanced_buttons2"] = []
    @tiny_mce_options["theme_advanced_buttons3"] = []
  end
    
  return
end

def breadcrumbs  # http://rubysnips.com
  return if params[:url] == nil
  r = []
  r << link_to("Home", "/")
  segments = params[:url].dup
  
  segments.each_with_index do |segment, i|
    
    page = Page.find_page((0..(i)).collect{|seg| segments[seg]}.join("/"))
    if page != nil && page.breadcrumb != nil && page.breadcrumb != ''
      title = page.breadcrumb
    else
      title = segment.titleize
      title.gsub!(/(\d)\s(\d)/, '\1-\2')
    end
    
    if session[:username]
      if i == segments.size - 1 && request.request_uri =~ /^\/edit\//  #last item in list
        r << (@pageform.text_field :breadcrumb, :title => 'edit breadcrumb') if @pageform != nil
        #r << link_to(title, "/staging/" + 
        #  (0..(i)).collect{|seg| segments[seg]}.join("/")) 
      elsif i == segments.size - 1  #last item in list
        r << link_to(title, "/edit/" + 
          (0..(i)).collect{|seg| segments[seg]}.join("/")) 
      else
        r << link_to(title, "/" + 
          (0..(i)).collect{|seg| segments[seg]}.join("/"))
      end
    elsif session[:username] == nil && i == segments.size - 1
      r << title  # unless user is logged in, last item in url beginning with staging is not a link
    else
      r << link_to_unless_current(title, "/" + 
        (0..(i)).collect{|seg| segments[seg]}.join("/"))
    end
  end
  
  return content_tag("div", r.join(" &#187; "), 
         :id => "crumbs")
end

def global_navigation
  nav = Navglobal.find(:all,
      :order => 'id')
  gn = []
  i = 1
  nav.each do |n|
    gn << content_tag("li", link_to(n.nameglobal, n.linkglobal), :class => "ng" + i.to_s) if n.nameglobal != nil && n.linkglobal != nil && n.nameglobal != "" && n.linkglobal != ""
    i += 1
  end
  return content_tag("ul", gn, :id => "navglobal")
end

def main_navigation
  nav = Navglobal.find(:all,
      :order => 'id')
  mn = []
  i = 1
  nav.each do |n|
    mn << content_tag("li", link_to(n.namemain, n.linkmain), :class => "nm" + i.to_s) if n.namemain != nil && n.linkmain != nil && n.namemain != "" && n.linkmain != ""
    i += 1
  end
  return content_tag("ul", mn, :id => "navmain")
end

def sitetree
  st = []
  st << '<link rel="StyleSheet" href="/javascripts/dtree/dtree.css" type="text/css" />
    <script type="text/javascript" src="/javascripts/dtree/dtree.js"></script>
    <p>Use the site navigation tree below to find another page.<br />Note: Names in [] aren&#039;t actual pages, only part of the site hierarchy.</p>
    <p><a href="javascript: a.openAll();">open all</a> |<a href="javascript: a.closeAll();">close all</a></p>
    
    <script type="text/javascript">
    a = new dTree("a");
    a.config.useIcons=false;
    a.config.useCookies=false;
    a.add(0,-1,"","javascript: void(0);");'
    
  @filenames = Filename.find(:all,
      :conditions => ["name != ?", 'add-new-page'],
      :order => 'name' )
  @pages = []
  i = 1
  fprev = []
  nodes = []
  nodes[0] = 0
  for filename in @filenames
    fcur = filename.name.split('/')
    0.upto(fcur.size - 1) do |j|
      if j == fcur.size - 1 && fcur[j] != fprev[j]
        st << 'a.add(' + i.to_s + ', ' + nodes[j].to_s + ', "' + fcur[j] + '","/' + filename.name + '");'
        nodes[j + 1] = i
        i += 1
      elsif fcur[j] != fprev[j]
        st << 'a.add(' + i.to_s + ', ' + nodes[j].to_s + ', "[' + fcur[j] + ']","javascript:void(0);");'
        nodes[j + 1] = i
        i += 1
      end 
    end  
    fprev = fcur.dup
  end 
  
    st << 'document.write(a);
    </script>'
  return st.to_s      

end

def title
  return if params[:url] == nil
  return if @page == nil || (!editing_page && @read_access_error == true) ||
    (!editing_page && @page_valid_message != '' && request.request_uri !~ /^\/staging/ && request.request_uri !~ /^\/pageid/)
  #return '<div class="notice">Page <i>' + params[:url].join("/") + '</i> does not exist on this server.</div>' + sitetree if @page == nil
  #if !editing_page && @read_access_error == true
  #  @page = nil
  #  if session[:username] == nil
  #    session[:original_uri] = request.request_uri 
  #    session[:previous_uri] = nil
  #    return '<div class="notice">Login required to read the page: <i>' + params[:url].join("/") + '</i></div><br />' + link_to("[login]", :controller => "login")
  #  else
  #    return '<div class="error">Access denied.  You do not have privileges to read this page.</div>'
  #  end
  #  session[:original_uri] = request.request_uri if session[:username] == nil
  #  session[:previous_uri] = nil if session[:username] == nil
  #  return '<div class="notice">Login required to read page: <i>' + params[:url].join("/") + '</i></div>' + ('<br />' + link_to("[login]", :controller => 'login') if session[:username] == nil)
  #end
  #
  #if !editing_page && @page_valid_message != '' && request.request_uri !~ /^\/staging/ && request.request_uri !~ /^\/pageid/
  #  @page = nil
  #  return '<div class="notice">' + @page_valid_message + '</div>' + sitetree
  #end
  
  c = []
  c << '<div id="pagetitle">'
  if editing_page
    c << edit_info()
    c << '<h1>'
    c << (@pageform.text_field :title, :title => 'edit title') if @pageform != nil
  else
    c << '<h1>'
    c << @page.title
  end
  c << '</h1>'
  c << '</div>  <!-- id="pagetitle" -->'
  return c 
end

def edit_info
  ei = []
  ei << '<div id="editinfo">'
  ei << '<p>'
  ei << 'Last modified: ' + @page.modified.strftime("%a %b %d, %Y at %I:%M %p %Z") + ' (' + @page.user.name + ')'
  ei << '</p>'
  ei << '</div id="editinfo">'
  return ei
end

def layout
  return if @page == nil || !editing_page
  c = []
  c << '<div class="ifile">'
  c << '<a href="/rubycms/layout/' + params[:url].join("/").to_s + '" ' + 'onclick="return hs.htmlExpand(this, { objectType: \'iframe\', targetX: \'layfrm -340px\', targetY: \'layfrm 2px\', width: 320, height: 120} )" >'
  c << '<div id="layfrm" title="Choose template for this page..." >'
  c << 'Layout'
  c << '</div></a>'
  c << '</div>'
  return c
end

def file_manager
  return if @page == nil || !editing_page
  c = []
  c << '<div class="ifile">'
  c << '<a href="/rubycms/filemanager/' + params[:url].join("/").to_s + '" ' + 'onclick="return hs.htmlExpand(this, { objectType: \'iframe\', targetX: \'fmfrm -340px\', targetY: \'fmfrm 2px\', width: 320, height: 600} )" >'
  c << '<div id="fmfrm" title="Import images and documents for article below..." >'
  c << 'Image & Document Manager'
  c << '</div></a>'
  c << '</div>'
  return c
end

def content
  return if @page == nil
  
  c = []
  if editing_page
    c << '<p>'
    c << (@pageform.text_area :content, :class => 'mceEditor') if @pageform != nil
    c << '</p>'
  else
    if request.request_uri =~ /^\/staging/ || request.request_uri =~ /^\/pageid/ || @version_list != nil
      c << '<div class="notice">' + @page_valid_message + '</div>' if @page_valid_message != ''
      c << '<div id="staging-versions">'
       
      c << (render(:partial => "staging"))
      c << '</div>'
    end
    c << '<div id="spotlightcontent">' if request.request_uri =~ /^\/(staging\/|edit\/)?spotlights\//
    c << (@page.content) if @page.content != nil
    c << '</div id="spotlightcontent">' if request.request_uri =~ /^\/(staging\/|edit\/)?spotlights\//
  end
  
  return c
end

def formbegin
  return if @page == nil || !editing_page
  o = []
 # o << (form_for :page, :url => {:action => :edit}, :html => {:multipart => true} do |@pageform| )

  return o
end

def formend
  return if @page == nil || !editing_page
  o = []
 # o << (end)
  return o
end

def formoptions
  return if @page == nil || !editing_page
  o = []
  
  o << '<div id="form-publish-container">'
  if @message_submit != nil && @message_submit != ""
    o << '<div class="success">'
    o << @message_submit
    o << '</div>'
  end
  
  fields_for :filename, @filename do |form_filename|
  o << '<div class="form-entry form-publish">'
  o << '<label for="name" title="Enter full URL path">Filename:</label>'
  o << (text_field_with_auto_complete :filename, :name, {:class => 'wide', :value => (@filename.name if @filename != nil)}, {:url => {:controller => 'site', :action => 'auto_complete_for_filename_name'}, :skip_style => true, :tokens => ','})
  o << '</div>'
  end

  fields_for :keyword, @keyword do |form_keyword|
  o << '<div class="form-entry form-publish">'
  o << '<label for="list" title="Enter keywords separated by a comma">Keywords:</label>'
  o << (text_field_with_auto_complete :keyword, :list, {:class => 'wide', :value => (@keyword.list if @keyword != nil)}, {:url => {:controller => 'site', :action => 'auto_complete_for_keyword_list'}, :skip_style => true, :tokens => ','})
  o << '</div>' 
  end
  
  o << '<div class="form-entry form-publish">'
  o << '<label for="published" title="Check to publish, uncheck to write draft">Publish:</label>'
  o << (@pageform.check_box :published) if @pageform != nil
  o << '</div>'
  
  o << '<div class="form-entry form-publish">'
  o << '<label for="valid_from" title="(Optional) Enter valid date/time range.  Leave blank to have page always available.">Valid from:</label>'
  o << (@pageform.text_field :valid_from, :title => 'valid from') if @pageform != nil
  o << '</div>'
  o << '<div class="form-entry form-publish">'
  o << '<label for="valid_to" title="(Optional) Enter valid date/time range.  Leave blank to have page always available.">Valid to:</label>'
  o << (@pageform.text_field :valid_to, :title => 'valid to') if @pageform != nil
  o << '</div>'
  
  o << '<div class="form-publish">'
  o << (submit_tag "Save")
  o << '</div>'
  o << '</div id="form-publish-container">'
  
  return o
end

def nav
  return if @page == nil
  
  n = []
  if editing_page
    
    n << '<div id="editnav">'
    n << '<ul id="navlist">' 
    0.upto(@nav_list.nav_list.size - 1) do |i|
      if @cur_navlist_item == i.to_s
        @navobj = @nav_list.nav_list[i]   #http://wiki.rubyonrails.org/rails/pages/InPlaceEditing
        n << content_tag("li", '<span id="handle">&uarr;&darr;&nbsp;</span>' +
          (in_place_editor_field :navobj, :name, {}, {:rows => 1, :cols => 30}) + '<br />' +
          (in_place_editor_field :navobj, :href, {}, {:rows => 1, :cols => 30}),
          :id => 'listitem' + i.to_s)
      else
        n << content_tag("li", '<span id="handle">&uarr;&darr;&nbsp;</span>' +
          (link_to_remote @nav_list.nav_list[i].name, :url => {:action => 'set_to_edit_mode', :cur_navlist_item => i}, :update => 'navlist'), :id => 'listitem' + i.to_s)
      end
    end
    n << '</ul>'
      n << (submit_tag 'Add', :class => 'editor_ok_button') 

    n << '<p id="navlistinfo"></p>'
    
    n << '</div>'
  else
    n << '<ul>'
    0.upto(@nav_list.nav_list.size - 1) do |i|
      n << content_tag("li", link_to(@nav_list.nav_list[i].name, @nav_list.nav_list[i].href))
    end
    n << '</ul>'
  end
  n << @cur_navlist_item
  
  return n
end

def username
  return if session[:username] == nil
  if request.request_uri =~ /^\/edit\//
    r = request.request_uri
  elsif request.request_uri =~ /^\/staging\//
    r = request.request_uri.sub('staging', 'edit')
  else
    r = "/edit" + request.request_uri
  end
  u = []
  u << '<div id="username">'
  u << link_to("+&nbsp;", "/edit/add-new-page", :title => 'new page')
  u << link_to("&bull;&nbsp;", r, :title => 'edit page')
  u << session[:username]
  u << '&nbsp; &nbsp;'
  u << link_to("&times;", {:controller => 'login', :action => 'logout'}, 
    {:title => 'logout'})  
  u << '</div>'
  return u
end

def hidden_div_if(condition, attributes = {})
  if condition
    attributes["style"] = "display: none"
  end
    a = tag_options(attributes.stringify_keys)
    "<div #{a}>"
end

def text_field_name_with_auto_complete(name, object, method, tag_options = {}, completion_options = {}, cont = params[:controller])  
  (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
  text_field(name, method, tag_options) +
  content_tag("div", "", :id => "#{object}_#{method}_auto_complete", :class => "auto_complete") +
  auto_complete_field("#{object}_#{method}", { :url => {:controller => cont, :action => "auto_complete_for_#{object}_#{method}" } }.update(completion_options))
end

# Allows multiple text fields grabbing autocomplete info from the same place
# http://groups.google.ca/group/rubyonrails-talk/browse_thread/thread/65f6f9011fa78b41/ca9a5a0abe8c461d?lnk=raot
def text_field_id_with_auto_complete(object, method, tag_options = {}, completion_options = {}, cont = params[:controller])
  # cont: an embedded form passes in its controller name (e.g. 'forms/admissions/prospect') otherwise the current controller is used
  # set the id and not worry about it throughout
  id = tag_options[:id] || "#{object}_#{method}"
  (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
  text_field(id, method, tag_options) +
  content_tag("div", "", :id => "#{id}_auto_complete", :class => "auto_complete") +
  auto_complete_field(id, { :url => {:controller => cont, :action => "auto_complete_for_#{object}_#{method}" } }.update(completion_options))
end

def text_field_with_auto_complete_multi(object, method, tag_options = {}, completion_options = {}, multi_options = {})
# Modification of text_field_with_auto_complete to allow multiple text fields grabbing autocomplete info from the same place
  # cont: an embedded form passes in its controller name (e.g. 'forms/admissions/prospect') otherwise the current controller is used
     if (multi_options[:index])
      tag_name = "#{object}_#{multi_options[:index]}_#{method}"
    else
      tag_name = "#{object}_#{method}"
    end
    tag_name = "#{object}_#{method}"
    #id = "#{object}_#{method}"
    
    cont = multi_options[:cont] || params[:controller]
    model = multi_options[:model] || object
    column = multi_options[:column] || method


    (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
        text_field(object, method, tag_options) +
        content_tag("div", "", :id => tag_name + "_auto_complete", :class => "auto_complete") +
        auto_complete_field(tag_name, {:url => {:controller => cont,  :action => "auto_complete_for_#{model}_#{column}" } }.update(completion_options))
end

end

# Fixes attachment_fu image loading problems on Windows
# http://epirsch.blogspot.com/2008/01/fixing-attachmentfu-on-windows-like.html
# http://www.ruby-forum.com/topic/99870
require 'tempfile'
  class Tempfile
    def size
      if @tmpfile
        @tmpfile.fsync # added this line
        @tmpfile.flush
        @tmpfile.stat.size
      else
        0
      end
    end
  end
  
Entry = Struct.new(:dir,:children)
def recurse(path)
 entry = Entry.new(path,[])

 #"." or ".." dirs will be replaced by the actual directory name
 Dir["#{path}/*"].each do |e|
   if File.directory?(e)
      entry.children <<  recurse(e)
   else
     # rigorous error checking not being performed
     if /\.rhtml$/ =~ e
       puts e.sub(/^(\.|\/)+/, "")
     end
   end
 end
end
