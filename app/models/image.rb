require 'model_helper'     # lib/model_helper.rb contains modules: RcmsModel and AttachmentFuModel

class Image < ActiveRecord::Base

  has_attachment :content_type => [:image, 'application/zip', 'application/x-tar', 'application/x-zip-compressed'],
                 :storage => :file_system, 
                 :max_size => RCMS_MAX_IMAGE_SIZE,
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
    i = {"tiny" => 36, "small" => 60, "medium" => 100, "large" => 180, "xlarge" => 480} 
    i.each do |name, size|
      # image with maximum width or height = size
      t = img.resize_to_fit(size, size)
      ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "#{name}" + "#{extension}"
      t.write(ifile)
      # uncomment destroy! when newer ImageMagick rpm released on server
      #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
      system("convert -quality 50 " + ifile + " " + ifile)
      # resize image to fit within the specified dimensions while retaining the original aspect ratio
      t = img.resize_to_fit(size, size * max_aspect_ratio) if img.columns <= img.rows
      t = img.resize_to_fit(size * max_aspect_ratio, size) if img.columns > img.rows
      ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "#{name}" + 'Ex' + "#{extension}"
      t.write(ifile)
      # uncomment destroy! when newer ImageMagick rpm released on server
      #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
      system("convert -quality 50 " + ifile + " " + ifile)
      t = img.crop(Magick::CenterGravity, [img.columns, img.rows].min, [img.columns, img.rows].min)
      t = t.resize_to_fit(size, size)
      ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "#{name}" + 'Sq' + "#{extension}"
      t.write(ifile)
      # uncomment destroy! when newer ImageMagick rpm released on server
      #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
      # gif resize bug: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=13010
      system ("convert +repage " + ifile + " " + ifile) if img.format == "GIF"
      system("convert -quality 50 " + ifile + " " + ifile)
      
    end
  end

  def self.create(page, filename, funique, url, session)
  # initialize instance variable @image_uploads and imageinfo list (ili) for site controller create definition
    image_uploads = Image.find(:all, :conditions => {:pathname => url})
    if funique == true
      # copy images used in content
      for i in image_uploads
        basename = File.basename(i.public_filename, ".*")
        if page.content =~ Regexp.new('(/images/)(' + i.pathname + '/)(' + basename + ')')
          extension = File.extname(i.public_filename)
          fn = ""
          if File.exist?("#{RAILS_ROOT}/public/system/images/" + i.pathname + "/" + basename + "_ORIG" + extension)
             fn = "#{RAILS_ROOT}/public/system/images/" + i.pathname + "/" + basename + "_ORIG" + extension
          elsif File.exist?("#{RAILS_ROOT}/public" + i.public_filename)
             fn = "#{RAILS_ROOT}/public" + i.public_filename
          end
          if fn != "" 
            fd = File.open(fn, "rb").read
            m = Image.new(:file_data => fd)
            m.filename = i.filename
            m.pathname = filename.name
            m.caption = i.caption
            m.content_type = i.content_type
            m.attachment_options[:path_prefix] = i.attachment_options[:path_prefix]
            m.create_thumbnails() if m.save
            page.content.gsub!("#{$1}#{$2}#{$3}", "#{$1}" + m.pathname + "/" + "#{$3}")
           end
        end
      end
    end

    il = Image.find(:all, :conditions => {:pathname => filename.name})
    ili = ""
    for i in il
      ili << "=(_8^(1)" if ili != ""
      ili << i.id.to_s + "@@@@8^)" + i.caption.to_s
    end
    
    #return image_uploads, ili, page
    g = {}
    g.default = image_uploads
    g["info"] = ili
    g["content"] = page.content
    return g
  end

  def self.make_info_current(page)
  # called when making a previous version current
    if page.imageinfo != nil && page.imageinfo != ""
      ili = page.imageinfo.split("=(_8^(1)")
      for i in ili
        ic = i.split("@@@@8^)")
        begin
          img = Image.find(ic[0].to_i)
        rescue
          # skip if file not found
        else
          img.caption = ic[1]
          img.save!
        end
      end
    end
  end

end
