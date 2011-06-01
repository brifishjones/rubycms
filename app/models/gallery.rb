require 'model_helper'     # lib/model_helper.rb contains modules: RcmsModel and AttachmentFuModel

class Gallery < ActiveRecord::Base

  has_attachment :content_type => [:image, 'application/zip', 'application/x-tar', 'application/x-zip-compressed'], 
                 :storage => :file_system, 
                 :max_size => RCMS_MAX_IMAGE_SIZE_GALLERY,
                 #:thumbnails => {:thumb50 => '50x50>'},
                 :path_prefix => "public/system/#{table_name}",
                 :processor => :Rmagick
                 
  validates_as_attachment 

  include AttachmentFuModel
  class << self
    include RcmsModel
  end

  def create_thumbnails()
    img = Magick::Image.read(attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + self.filename).first
    basename = File.basename(self.filename, ".*")
    extension = self.filename.scan(/\.\w+$/)
    max_image_size = 720
    
    # name uploaded file ORIG
    img.write(attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "ORIG" + "#{extension}" )
    # reduce image if necessary
    if img.columns > max_image_size || img.rows > max_image_size
      img = img.resize_to_fit(max_image_size, max_image_size) 
    end
    ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + self.filename
    img.write(ifile) { self.quality = 50 }
    # call ImageMagick command "convert" to reduce file size
    #system("convert -quality 50 " + ifile + " " + ifile)
    
    # thumbnail size for gallery (Sq extension)
    # Do not change.  Used for display and in regex searches  
    i = {"small" => 68, "medium" => 80, "large" => 96} 
    i.each do |name, size|
      t = img.crop(Magick::CenterGravity, [img.columns, img.rows].min, [img.columns, img.rows].min)
      t = t.resize_to_fit(size, size)
      ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "#{name}" + 'Sq' + "#{extension}"
      t.write(ifile) { self.quality = 50 }
      # uncomment destroy! when newer ImageMagick rpm released on server
      #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
      # gif resize bug: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=13010
      system ("convert +repage " + ifile + " " + ifile) if img.format == "GIF"
      #system("convert -quality 50 " + ifile + " " + ifile)
    end  
  end

  def self.edit(page, url, session)
    g = {"url" => url.dup, "text" => 'Edit image gallery'}
    g.default = Gallery.find(:all, :conditions => {:pathname => url.join("/"), :rank => 1..RCMS_MAX_GALLERY}, :order => "rank")
    session[:gallery] = g.default
    return g
  end
  
  def self.edit_refresh(id, url, session)
  # initialize instance variables @gallery_url, @gallery_uploads, and @gallery_text for site controller edit_refresh definition
    g = {"url" => url.dup, "text" => 'Edit image gallery'}
    g.default = session[:gallery]
    return g
  end
  
  def self.create(fname, funique, url, session)
    return create_full(fname, funique, url, session[:gallery], RCMS_MAX_GALLERY)
  end
  
  def self.update_rjs(session)
  # called to refresh appropriate part of page after closing iframe in edit mode
    g = {"url" => session[:url]}
    g.default = session[:gallery]
    return g
  end

end
