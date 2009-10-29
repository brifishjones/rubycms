class Rubycms::ImagetopController < ApplicationController

  def show
    #flash[:notice] = params[:url].inspect
    params[:url] = Array.new if params[:url] == nil
    @imagetop = {}
    @imagetop.default = Imagetop.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @imagetop["edit_caption"] = false
    @imagetop["current"] = session[:image_top]
    @upload_privileges = get_upload_privileges
  end 
  
  def imagetop_upload
    params[:path] = Array.new if params[:path] == nil
    @imagetop = {}
    @imagetop.default = Imagetop.find(:all, :conditions => {:pathname => params[:path].join("/")})
    @imagetop["current"] = Imagetop.new(params[:imagetop])
    if @imagetop["current"].filename == nil
      redirect_to :controller => '/rubycms_imagetop', :action => 'show', :url => params[:path]
      return
    end
    @imagetop["current"].pathname = params[:path].join('/')
    
    basename = File.basename(@imagetop["current"].filename, ".*")
    extension = @imagetop["current"].filename.scan(/\.\w+$/)
    @imagetop["current"].filename = "#{basename}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
    
    if @imagetop["current"].save
      #flash[:notice] = 'Image was successfully saved.'
      @imagetop["current"].create_thumbnails()
      session[:image_top] = @imagetop["current"]
    else
      flash[:notice] = 'Image NOT saved.'
    end
    redirect_to :controller => '/rubycms_imagetop', :action => 'show', :url => params[:path]
  end
  
  def remove_imagetop
    params[:url] = Array.new if params[:url] == nil
    @imagetop = {}
    @imagetop.default = Imagetop.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @imagetop["current"] = nil
    session[:image_top] = @imagetop["current"]
    render :update do |page|
      page.replace_html("imagetopcap", :partial => "rubycms/imagetop/imagetop")
    end
  end
  
  def edit_imagetop_caption
    params[:url] = Array.new if params[:url] == nil
    @imagetop = {}
    @imagetop.default = Imagetop.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @imagetop["current"] = Imagetop.find(params[:id])
    session[:image_top] = @imagetop["current"]
    render :update do |page|
      page.replace_html("imagetopcap", :partial => "rubycms/imagetop/imagetop")
    end
  end
  
  def update_imagetop_caption
    params[:url] = Array.new if params[:url] == nil
    @imagetop = {"current" => Imagetop.find(params[:id])}
    @imagetop["current"].caption = params[:caption]
    @imagetop["current"].save
    @imagetop.default = Imagetop.find(:all, :conditions => {:pathname => params[:url].join("/")})
    render :update do |page|
      page.replace_html("imagetopcap", :partial => "rubycms/imagetop/imagetop")
    end
  end
  
  def cancel_imagetop_caption
    params[:url] = Array.new if params[:url] == nil
    @imagetop = {}
    @imagetop.default = Imagetop.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @imagetop["current"] = Imagetop.find(params[:id])
    render :update do |page|
      page.replace_html("imagetopcap", :partial => "rubycms/imagetop/imagetop")
    end
  end
end
