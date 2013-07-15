class Rubycms::FilemanagerController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @image = {}
    @image.default = Image.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @image["edit_caption"] = false
    @image["current"] = nil
    @fileupload = {}
    @fileupload.default = Fileupload.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @upload_privileges = get_upload_privileges
  end 

  def image_upload
    require 'zip/zip'   #ruby gem "rubyzip" (rubyzip.sourceforge.net)
    params[:path] = Array.new if params[:path] == nil
    @image = Image.new(params[:image])
    if @image.filename == nil
      redirect_to :controller => '/rubycms_filemanager', :action => 'show', :url => params[:path]
      return
    end
    @image.pathname = params[:path].join('/')
    basename = File.basename(@image.filename, ".*")
    extension = @image.filename.scan(/\.\w+$/)
    
    if @image.content_type.inspect =~ /application\/x?\-?(zip|tar)/
      #'application/zip', 'application/x-tar', 'application/x-zip-compressed'
      flash[:notice] = ""
      Zip::ZipInputStream::open(@image.temp_path) do |io|
        while (entry = io.get_next_entry)
          flash[:notice] << "Contents of #{File.basename(entry.name)}"
          io.rewind
          fd = io.read
          if entry.size > 0
            #flash[:notice] << "#{fd}"
            #entry.extract(File.basename(entry.name))  # creates file in application root directory                       
            begin
              # For list of formats see http://www.imagemagick.org/script/formats.php
              format = Magick::Image.from_blob(StringIO.new(fd).read).first.format
            rescue
              # skip if file can't be read by ImageMagick
            else
              image_item = Image.new(:file_data => fd)
              extension = File.basename(entry.name).scan(/\.\w+$/)
              image_item.filename = "#{File.basename(entry.name, ".*")}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
              image_item.pathname = params[:path].join('/')
              flash[:notice] << "#{format}"
              # only allow JPEG, GIF, and PNG
              case format
              when 'JPEG'
                image_item.content_type = 'image/jpg'
              when 'GIF'
                image_item.content_type = 'image/gif'
              when 'PNG'
                image_item.content_type = 'image/png'
              end
       
              image_item.attachment_options[:path_prefix] = @image.attachment_options[:path_prefix]
              image_item.caption = ''
          
              if image_item.save
                flash[:notice] << "#{File.basename(entry.name).type.inspect} #{image_item.filename} #{image_item.attachment_options[:path_prefix]} #{image_item.pathname} #{image_item.content_type}  "
                image_item.create_thumbnails()
              else
                flash[:notice] << "#{File.basename(entry.name).type.inspect} #{image_item.filename} #{image_item.attachment_options[:path_prefix]} #{image_item.pathname} #{image_item.content_type} NOT saved.  "
              end
            end
          end
        end
      end
    else
      @image.filename = "#{basename}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
      @image.caption = ''
      if @image.save
        #flash[:notice] = 'Image was successfully saved.'
        @image.create_thumbnails()
      else
        flash[:notice] = 'Image NOT saved.'   
      end
    end
  
    redirect_to :controller => '/rubycms_filemanager', :action => 'show', :url => params[:path]
  end

  def file_upload
    params[:path] = Array.new if params[:path] == nil
    @upload = Fileupload.new(params[:fileupload])
    if @upload.filename == nil
      redirect_to :controller => '/rubycms_filemanager', :action => 'show', :url => params[:path]
      return
    end
    @upload.pathname = params[:path].join('/')
    basename = File.basename(@upload.filename, ".*")
    extension = @upload.filename.scan(/\.\w+$/)
    @upload.filename = "#{basename}#{Time.now.strftime("%Y%m%d%H%M%S")}#{extension}"
    
    # firefox 5 on Mac OS X 10.6.7 thinks pdfs have content type 'image/ipeg'  Added workaround
    # http://codeigniter.com/forums/viewthread/140480/#698879
    # firefox 22 on Mac OS X 10.6.8 thinks pdfs have content type 'application/x-download' Added workaround
    if @upload.content_type.inspect =~ /application\/x?\-?(pdf|download)/ || @upload.content_type.inspect =~ /image\/ipeg/
      if @upload.save
        flash[:notice] = 'pdf was successfully saved.'
      else
        flash[:notice] = 'pdf NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /application\/x?\-?shockwave-flash/
      if @upload.save
        flash[:notice] = 'flash was successfully saved.'
      else
        flash[:notice] = 'flash NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /application\/x?\-?msword/
      if @upload.save
        flash[:notice] = 'word doc was successfully saved.'
      else
        flash[:notice] = 'word doc NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /application\/v?n?d?\.?x?\-?m?s?\-?excel/
      if @upload.save
        flash[:notice] = 'excel was successfully saved.'
      else
        flash[:notice] = 'excel NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /text\/x?\-?rtf/
      if @upload.save
        flash[:notice] = 'rtf was successfully saved.'
      else
        flash[:notice] = 'rtf NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /text\/x?\-?plain/
      if @upload.save
        flash[:notice] = 'text file was successfully saved.'
      else
        flash[:notice] = 'text file NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /application\/x?\-?(zip|tar)/
      if @upload.save
        flash[:notice] = 'zip file was successfully saved.'
      else
        flash[:notice] = 'zip file NOT saved.'
      end
    elsif @upload.content_type.inspect =~ /application\/octet\-stream/
      if @upload.save
        flash[:notice] = 'binary file was successfully saved.'
      else
        flash[:notice] = 'binary file NOT saved.'
      end
    else
      flash[:notice] = 'upload of the ' + @upload.content_type.inspect + ' file format not supported'
    end
    redirect_to :controller => '/rubycms_filemanager', :action => 'show', :url => params[:path]
  end
  
  def delete_file
    # hide file by adding 'HIDEm4afK6RpFILE' to beginning of filename
    # won't affect files already placed on page
    f = Fileupload.find(params[:id])
    f.filename = "HIDEm4afK6RpFILE" + f.filename if /^HIDEm4afK6RpFILE/ !~ f.filename
    f.save
    @fileupload = {}
    @fileupload.default = Fileupload.find(:all, :conditions => {:pathname => params[:url].join("/")})
    render :update do |page|
      page.replace_html("fileuploadlist", :partial => "rubycms/filemanager/file_upload_list")
    end
  end
  
  def delete_image
    # hide image by adding 'HIDEe584f2e1ed91IMAGE' to beginning of caption
    # won't affect images already placed on page
    params[:url] = Array.new if params[:url] == nil
    @image = {"current" => Image.find(params[:id])}
    @image["current"].caption = "HIDEe584f2e1ed91IMAGE" + @image["current"].caption if /^HIDEe584f2e1ed91IMAGE/ !~ @image["current"].caption
    @image["current"].save
    @image["edit_caption"] = false
    @image.default = Image.find(:all, :conditions => {:pathname => params[:url].join("/")})
    render :update do |page|
      page.replace_html("imgcap", :partial => "rubycms/filemanager/image_caption")
    end
  end

  def edit_image_caption
    params[:url] = Array.new if params[:url] == nil
    @image = {}
    @image.default = Image.find(:all, :conditions => {:pathname => params[:url].join("/")})
    @image["current"] = Image.find(params[:id])
    @image["edit_caption"] = true
    render :update do |page|
      page.replace_html("imgcap", :partial => "rubycms/filemanager/image_caption")
    end
  end
  
  def update_image_caption
    params[:url] = Array.new if params[:url] == nil
    @image = {"current" => Image.find(params[:id])}
    @image["current"].caption = params[:caption]
    @image["current"].save
    @image["edit_caption"] = false
    @image.default = Image.find(:all, :conditions => {:pathname => params[:url].join("/")})
    render :update do |page|
      page.replace_html("imgcap", :partial => "rubycms/filemanager/image_caption")
    end
  end
  
  def cancel_image_caption
    params[:url] = Array.new if params[:url] == nil
    @image = {"edit_caption" => false, "current" => nil}
    @image.default = Image.find(:all, :conditions => {:pathname => params[:url].join("/")})
    render :update do |page|
      page.replace_html("imgcap", :partial => "rubycms/filemanager/image_caption")
    end
  end

end
