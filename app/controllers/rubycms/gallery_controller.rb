class Rubycms::GalleryController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @gallery = {}
    if session[:gallery] == nil
      @gallery.default = Gallery.find(:all, :conditions => {:pathname => params[:url].join("/")}, :rank => 1..RCMS_MAX_GALLERY, :order => "rank")
      session[:gallery] = @gallery.default
    else
      @gallery.default = session[:gallery]
    end
    @gallery["edit_caption"] = false
    @gallery["current"] = nil
    @upload_privileges = get_upload_privileges
  end

  def gallery_upload
    require 'zip/zip'   #ruby gem "rubyzip" (rubyzip.sourceforge.net)
    params[:path] = Array.new if params[:path] == nil
    @gu = Gallery.new(params[:gallery])
    if @gu.filename == nil
      redirect_to :controller => '/rubycms_gallery', :action => 'show', :url => params[:path]
      return
    end
    @gu.pathname = params[:path].join('/')
    basename = File.basename(@gu.filename, ".*")
    extension = @gu.filename.scan(/\.\w+$/)
    #flash[:notice] = "#{basename} #{extension}  #{@gu.pathname}   #{@gu.attachment_options[:path_prefix]}  #{@gu.content_type.inspect} #{@gu.temp_path}"
    i = session[:gallery].size + 1
    
    # Note: there are problems reading zip files created by right-clicking and choosing Compress on Mac OS 10.5,
    # therefore command line is recommended instead: e.g. zip archive.zip *.jpg
    if @gu.content_type.inspect =~ /application\/x?\-?(zip|tar)/
      #'application/zip', 'application/x-tar', 'application/x-zip-compressed'
      flash[:notice] = ""
      Zip::ZipInputStream::open(@gu.temp_path) do |io|
        while (entry = io.get_next_entry)
          flash[:notice] << "Contents of #{File.basename(entry.name)}" + " #{entry.size}"
          
          io.rewind
          fd = io.read
          if entry.size > 0 # && File.basename(entry.name)[0] != "."   # not a hidden file
            #flash[:notice] << "#{fd}"
            #entry.extract(File.basename(entry.name))  # creates file in application root directory  
            begin
              # For list of formats see http://www.imagemagick.org/script/formats.php
              format = Magick::Image.from_blob(StringIO.new(fd).read).first.format
            rescue
              # skip if file can't be read by ImageMagick
            else
              #flash[:notice] << "#{format}"
              image_item = Gallery.new(:file_data => fd)
              extension = File.basename(entry.name).scan(/\.\w+$/)
              image_item.filename = "#{File.basename(entry.name, ".*")}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
              image_item.pathname = params[:path].join('/')
              # only allow JPEG, GIF, and PNG
              case format
              when 'JPEG'
                image_item.content_type = 'image/jpg'
              when 'GIF'
                image_item.content_type = 'image/gif'
              when 'PNG'
                image_item.content_type = 'image/png'
              end
       
              image_item.attachment_options[:path_prefix] = @gu.attachment_options[:path_prefix]
              image_item.rank = i
              image_item.caption = ''
              image_item.show = true
        
              if image_item.save
                #flash[:notice] << "#{i} #{File.basename(entry.name).type.inspect} #{image_item.filename} #{image_item.attachment_options[:path_prefix]} #{image_item.pathname} #{image_item.content_type}  "
                i += 1
                image_item.create_thumbnails()
                session[:gallery] << image_item
              else
                flash[:notice] << "#{i} #{File.basename(entry.name).type.inspect} #{image_item.filename} #{image_item.attachment_options[:path_prefix]} #{image_item.pathname} #{image_item.content_type} NOT saved.  "
              end
            end
          end
        end
      end
    else
      @gu.filename = "#{basename}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
      @gu.rank = i
      @gu.caption = ''
      @gu.show = true
      if @gu.save
        #flash[:notice] = 'Image was successfully saved.'
        @gu.create_thumbnails()
        session[:gallery] << @gu
      else
        flash[:notice] = 'Image NOT saved.'
      end    
    end
    
    redirect_to :controller => '/rubycms_gallery', :action => 'show', :url => params[:path]
  end

  def order_gallery_images
    @page = Page.find(params[:page])
    @sorting = params[:sorting]    
    @gallery = {"edit_caption" => false}
    @upload_privileges = get_upload_privileges
    
    bu = session[:gallery].dup
    0.upto(session[:gallery].size - 1) do |i|
      bu[i] = session[:gallery][params[:galleryimages][i].to_i]
      #flash[:notice] << "#{i}  #{session[:gallery][i].id} #{session[:gallery][i].filename} #{bu[i].id} #{bu[i].filename}"
    end
    @gallery.default = bu
    session[:gallery] = bu
    render :partial => 'gallery' 
  end 
  
  def delete_gallery_image
  # remove gallery image from current list.  Gallery image itself is retained for previous versions.
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @index = params[:index]
    @gallery = {"edit_caption" => false, "current" => nil}
    session[:gallery].delete_at(@index.to_i)
    @gallery.default = session[:gallery]
    @upload_privileges = get_upload_privileges
    render :update do |page|
      page.replace_html("gallerycap", :partial => "rubycms/gallery/gallery")
    end
  end

  def edit_gallery_caption
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @gallery = {}
    @gallery.default = session[:gallery]
    @gallery["current"] = Gallery.find(params[:id])
    @gallery["edit_caption"] = true
    render :update do |page|
      page.replace_html("gallerycap", :partial => "rubycms/gallery/gallery")
    end
  end  
  
  def update_gallery_caption
    #note: title not showing on hover after update
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @gallery = {"current" => Gallery.find(params[:id]), "edit_caption" => false}
    c = session[:gallery].index(@gallery["current"])
    @gallery["current"].caption = params[:caption]
    @gallery["current"].show = params[:show]
    @gallery["current"].save
    flash[:notice] = "-->#{c} #{@gallery["current"].id} #{session[:gallery][c].id} #{@gallery["current"].filename} #{@gallery["current"].caption} #{@gallery["current"].show}"
    session[:gallery][c] = @gallery["current"]
    @upload_privileges = get_upload_privileges
    @gallery.default = session[:gallery]
    render :update do |page|
      page.replace_html("gallerycap", :partial => "rubycms/gallery/gallery")
    end
  end

  def cancel_gallery_caption
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @gallery = {"edit_caption" => false, "current" => nil}
    @gallery.default = session[:gallery]
    @upload_privileges = get_upload_privileges
    render :update do |page|
      page.replace_html("gallerycap", :partial => "rubycms/gallery/gallery")
    end
  end

end
