class Rubycms::ImagesideController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @imageside = {}
    if session[:image_side] == nil
      @imageside.default = Imageside.find(:all, :conditions => {:pathname => params[:url].join("/")}, :rank => 1..MAX_IMAGESIDE, :order => "rank") 
      session[:image_side] = @imageside.default
    else
      @imageside.default = session[:image_side]
    end
    @upload_privileges = get_upload_privileges
  end 
  
  def imageside_upload
    params[:path] = Array.new if params[:path] == nil
    @image = Imageside.new(params[:imageside])
    if @image.filename == nil
      redirect_to :controller => '/rubycms_imageside', :action => 'show', :url => params[:path]
      return
    end
    @image.pathname = params[:path].join('/')
    basename = File.basename(@image.filename, ".*")
    extension = @image.filename.scan(/\.\w+$/)
    @image.filename = "#{basename}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
    @image.rank = params[:size].to_i + 1
    @image.href = ''
    @image.caption = ''
    @image.show = false
    
    if @image.save
      #flash[:notice] = 'Image was successfully saved.'
      @image.create_thumbnails()
      session[:image_side] << @image   
    else
      flash[:notice] = 'Image NOT saved.'
    end
    redirect_to :controller => '/rubycms_imageside', :action => 'show', :url => params[:path]
  end
  
  def order_imageside_sections
    @page = Page.find(params[:page])
    @imageside = {}
    bu = session[:image_side].dup
    0.upto(session[:image_side].size - 1) do |i|
      bu[i] = session[:image_side][params[:imageside][i].to_i]
    end
    @imageside.default = bu
    session[:image_side] = bu
    render :partial => 'imageside' 
  end 
  
  def delete_imageside
  # remove side image from current list.  Imageside itself is retained for previous versions.
    @page = Page.find(params[:page])
    @imageside = {}
    @section = params[:section]
    session[:image_side].delete_at(@section.to_i)
    @imageside.default = session[:image_side]
    render :update do |page|
      page.replace_html("imagesidecap", :partial => "rubycms/imageside/imageside")
    end
  end
  
  def update_imageside_text_field
    @page = Page.find(params[:page])
    @imageside = {}
    @section = params[:section]
    session[:image_side][@section.to_i].caption = params[:update_imageside_text_field]
    @imageside.default = session[:image_side]
    render :partial => 'imageside'
  end 
  
  def update_imageside_href_text_field
    @page = Page.find(params[:page])
    @imageside = {}
    @section = params[:section]
    session[:image_side][@section.to_i].href = params[:update_imageside_href_text_field]
    @imageside.default = session[:image_side]
    render :partial => 'imageside'
  end
  
  def update_imageside_show
    @page = Page.find(params[:page])
    @imageside = {}
    @section = params[:section]
    if params[:update_imageside_show] != '1'
      session[:image_side][@section.to_i].show = false
    else
      session[:image_side][@section.to_i].show = true
    end
    @imageside.default = session[:image_side]
    render :partial => 'imageside'
  end

end
