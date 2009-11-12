require 'model_helper'     # lib/model_helper.rb contains modules: RcmsModel and AttachmentFuModel

class Imagetop < ActiveRecord::Base

  has_many :pages
  
  has_attachment :content_type => :image, 
                 :storage => :file_system, 
                 :max_size => 8.megabytes,
                 #:thumbnails => {:thumb50 => '50x50>'},
                 :path_prefix => "public/system/#{table_name}",
                 :processor => :Rmagick
                 
  validates_as_attachment    

  include AttachmentFuModel
  class << self
    include RcmsModel
  end
  
  # attachment_fu image upload given a url
  # attach an image by providing its url, rather than uploading
  # to the system via a form
  # can be used to batch upload images to server
  # http://significantbits.wordpress.com/2007/04/06/using-attachment_fu-by-techno-weenie-to-add-image-attachment-support-to-your-rails-application/
  def source_url=(url)
    return nil if not url
    http_getter = Net::HTTP
    uri = URI.parse(url)
    response = http_getter.start(uri.host, uri.port) {|http|
      http.get(uri.path)
    }
    case response
    when Net::HTTPSuccess
      file_data = response.body
      return nil if file_data.nil? || file_data.size == 0
      self.content_type = response.content_type
      self.temp_data = file_data
      self.filename = uri.path.split('/')[-1]
    else
      return nil
    end
  end
 
      
  def create_thumbnails()
    img = Magick::Image.read(attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + self.filename).first
    basename = File.basename(self.filename, ".*")
    extension = self.filename.scan(/\.\w+$/)
    max_image_size = 980
    max_aspect_ratio = 10
    max_thumb_size = 96
    
    # name uploaded file ORIG
    img.write(attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "ORIG" + "#{extension}" )
    
    img = img.resize_to_fit(max_image_size, max_image_size * max_aspect_ratio) if img.columns > max_image_size
    ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + self.filename
    img.write(ifile)
    # call ImageMagick command "convert" to reduce file size
    # gif resize bug: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=13010
    img.format == "GIF" ? system("convert +repage " + ifile + " " + ifile) : system("convert -quality 50 " + ifile + " " + ifile)
    
    img = img.resize_to_fit(max_thumb_size, max_thumb_size * max_aspect_ratio) if img.columns > max_thumb_size
    ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "thumb" + "#{extension}"
    img.write(ifile)
    img.format == "GIF" ? system("convert +repage " + ifile + " " + ifile) : system("convert -quality 50 " + ifile + " " + ifile)
    
    # uncomment destroy! when newer ImageMagick rpm released on server
    #img.destroy!  #important to free memory because Rmagick doesn't do it automatically.

  end

  def self.show(id, info)
  # initialize instance variable @imagetop for site controller show definition
    g = {}
    if id == nil
      g["current"] = nil
    else
      begin
        g["current"] = Imagetop.find(id)
      rescue ActiveRecord::RecordNotFound
        g["current"] = nil
      else
      end
    end
    return g
  end

  def self.edit(page, url, session)
    g = {"url" => url.dup, "text" => 'Edit top image'}
    g.default = Imagetop.find(:all, :conditions => {:pathname => url.join("/")})
      
    if page.imagetop_id == nil
      g["current"] = nil
    else
      begin
        g["current"] = Imagetop.find(page.imagetop_id)
      rescue ActiveRecord::RecordNotFound
        g["current"] = nil
      else
      end    
    end
    session[:imagetop] = g["current"]
    return g
  end

  def self.edit_refresh(id, url, session)
  # initialize instance variables @imagetop, @imagetop_url, @imagetop_uploads, and @imagetop_text for site controller edit_refresh definition
    g = {"url" => url.dup, "text" => 'Edit top image', "current" => session[:imagetop]}
    g.default = Imagetop.find(:all, :conditions => {:pathname => url})
    return g
  end
  
  def self.update_rjs(session)
  # called to refresh appropriate part of page after closing iframe in edit mode
    return {"url" => session[:url], "current" => session[:imagetop], "updating" => 'yes'}
  end

  def self.create(page, filename, funique, url, session)
  # initialize instance variable @imagetop and imagetopinfo list (tli) for site controller create definition  
    imagetop = session[:imagetop]
    if imagetop != nil && funique == true
      begin
        fd = File.open("#{RAILS_ROOT}/public" + imagetop.public_filename, "rb").read
      rescue
        imagetop = nil
      else
        t = Imagetop.new(:file_data => fd)
        t.filename = imagetop.filename
        t.pathname = filename.name
        t.caption = imagetop.caption
        t.href = imagetop.href
        t.content_type = imagetop.content_type
        t.attachment_options[:path_prefix] = imagetop.attachment_options[:path_prefix]
        t.create_thumbnails() if t.save
        imagetop = t
      end
    end
    
    # imagetopinfo list
    tli = ""
    tli = imagetop.id.to_s + "@@@@8^)" + imagetop.caption.to_s + "@@@@8^)" + imagetop.href.to_s if imagetop != nil
    
    #return imagetop, tli
    return {"current" => imagetop, "info" => tli}
  end

  def self.make_info_current(page)
  # called when making a previous version current
    if page.imagetopinfo != nil && page.imagetopinfo != ""
      tc = page.imagetopinfo.split("@@@@8^)")
      begin
        img = Imagetop.find(tc[0].to_i)
      rescue
        # skip if file not found
      else
        img.caption = tc[1]
        img.href = tc[2]
        img.save!
      end
    end
  end

end
