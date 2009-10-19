class Rubycms::BannerController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @banner = {}
    if session[:banner] == nil
      @banner.default = Banner.find(:all, :conditions => {:pathname => params[:url].join("/")}, :rank => 1..MAX_BANNER, :order => "rank") 
      session[:banner] = @banner.default
    else
      @banner.default = session[:banner]
    end
    @upload_privileges = get_upload_privileges
  end 
  
  def banner_upload
    params[:path] = Array.new if params[:path] == nil
    @image = Banner.new(params[:banner])
    if @image.filename == nil
      redirect_to :controller => '/rubycms_banner', :action => 'show', :url => params[:path]
      return
    end
    @image.pathname = params[:path].join('/')
    
    basename = File.basename(@image.filename, ".*")
    extension = @image.filename.scan(/\.\w+$/)
    @image.filename = "#{basename}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
    @image.rank = params[:size].to_i + 1
    @image.href = ''
    @image.caption = 'Enter\ndescription\nfor\nimage'
    @image.show = false
    
    if @image.save
      @image.create_thumbnails()
      session[:banner] << @image
    else
      flash[:notice] = 'Image NOT saved.'
    end
    redirect_to :controller => '/rubycms_banner', :action => 'show', :url => params[:path]
  end

  def order_banner_sections
    @page = Page.find(params[:page])
    @banner = {}
    bu = session[:banner].dup
    0.upto(session[:banner].size - 1) do |i|
      bu[i] = session[:banner][params[:banner][i].to_i]
    end
    @banner.default = bu
    session[:banner] = bu
    render :partial => 'banner'
  end 
  
  def delete_banner
  # remove banner from current list.  Banner itself is retained for previous versions.
    @page = Page.find(params[:page])
    @banner = {}
    @section = params[:section]
    session[:banner].delete_at(@section.to_i)
    @banner.default = session[:banner]
    render :update do |page|
      page.replace_html("bannercap", :partial => "rubycms/banner/banner")
    end
  end
  
  def update_banner_text_field
    @page = Page.find(params[:page])
    @banner = {}
    @section = params[:section]
    @line = params[:line]
    cap = session[:banner][@section.to_i].caption.split('\n')
    cap[@line.to_i] = params[:update_banner_text_field]
    session[:banner][@section.to_i].caption = ''
    0.upto(3) do |i|
      cap [i] = '' if cap[i] == nil
      session[:banner][@section.to_i].caption << cap[i]
      session[:banner][@section.to_i].caption << '\n' if i != 3
    end
    @banner.default = session[:banner]
    render :partial => 'banner'
  end 
  
  def update_banner_href_text_field
    @page = Page.find(params[:page])
    @banner = {}
    @section = params[:section]
    session[:banner][@section.to_i].href = params[:update_banner_href_text_field]
    @banner.default = session[:banner]
    render :partial => 'banner'
  end
  
  def update_banner_show
    @page = Page.find(params[:page])
    @banner = {}
    @section = params[:section]
    if params[:update_banner_show] != '1'
      session[:banner][@section.to_i].show = false
    else
      session[:banner][@section.to_i].show = true
    end
    @banner.default = session[:banner]
    render :partial => 'banner'
  end
end
