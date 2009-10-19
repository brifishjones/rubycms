require 'model_helper'     # lib/model_helper.rb contains modules: RcmsModel and AttachmentFuModel

class Imageside < ActiveRecord::Base

  has_many :pages
  
  has_attachment :content_type => :image, 
                 :storage => :file_system, 
                 :max_size => 5.megabytes,
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
    max_aspect_ratio = 10
    max_image_size = 720
    
    # name uploaded file ORIG
    img.write(attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "ORIG" + "#{extension}" )
    # reduce image if necessary
    if img.columns > max_image_size || img.rows > max_image_size
      img = img.resize_to_fit(max_image_size, max_image_size) 
    end
    ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + self.filename
    img.write(ifile)
    # call ImageMagick command "convert" to reduce file size
    system("convert -quality 50 " + ifile + " " + ifile) 
    
    # names for different thumbnail sizes (including Ex and Sq extensions)
    # Do not change.  Used for display and in regex searches  
    i = {"small" => 180, "medium" => 240, "large" => 300} 
    i.each do |name, size|
      # resize image to fit within the specified dimensions while retaining the original aspect ratio
      t = img.resize_to_fit(size, size * max_aspect_ratio) if img.columns <= img.rows
      t = img.resize_to_fit(size * max_aspect_ratio, size) if img.columns > img.rows
      ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "#{name}" + 'Ex' + "#{extension}"
      t.write(ifile)
      # uncomment destroy! when newer ImageMagick rpm released on server
      #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
      system("convert -quality 50 " + ifile + " " + ifile)
    end
    t = img.crop(Magick::CenterGravity, [img.columns, img.rows].min, [img.columns, img.rows].min)
    t = t.resize_to_fit(86, 86)
    ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + 'thumb' + 'Sq' + "#{extension}"
    t.write(ifile)
    # uncomment destroy! when newer ImageMagick rpm released on server
    #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
    # gif resize bug: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=13010
    system ("convert +repage " + ifile + " " + ifile) if img.format == "GIF"
    system("convert -quality 50 " + ifile + " " + ifile)
  end

  def self.edit(page, url, session)
    g = {"url" => url.dup, "text" => 'Edit sidebar images'}
    g.default = Imageside.find(:all, :conditions => {:pathname => url.join("/"), :rank => 1..MAX_IMAGESIDE}, :order => "rank")
    session[:image_side] = g.default
    return g
  end
  
  def self.edit_refresh(id, url, session)
  # initialize instance variables @imageside_url, @imageside_uploads, and @imageside_text for site controller edit_refresh definition
    g = {"url" => url.dup, "text" => 'Edit sidebar images'}
    g.default = session[:image_side]
    return g
    
  end
  
  def self.update_rjs(session)
  # called to refresh appropriate part of page after closing iframe in edit mode
    s = {"url" => session[:url]}
    s.default = session[:image_side]
    return s
  end

end
