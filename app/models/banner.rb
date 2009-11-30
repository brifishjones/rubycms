require 'model_helper'     # lib/model_helper.rb contains modules: RcmsModel and AttachmentFuModel

class Banner < ActiveRecord::Base

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
    
    if img.columns * 3 >= img.rows * 4   # wider than 4:3 aspect ratio
      t = img.crop(Magick::CenterGravity, img.rows * 4 / 3, img.rows)
    else
      t = img.crop(Magick::CenterGravity, img.columns, img.columns * 3 / 4)
    end
    t = t.resize(114, 86)
    ifile = attachment_options[:path_prefix].to_s + '/' + self.pathname + '/' + "#{basename}" + '_' + "thumb" + "#{extension}"
    t.write(ifile)
    # uncomment destroy! when newer ImageMagick rpm released on server
    #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
    # gif resize bug: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=13010
    system ("convert +repage " + ifile + " " + ifile) if img.format == "GIF"
  end

  def self.edit(page, url, session)
    g = {"url" => url.dup, "text" => 'Edit banners'}
    g.default = Banner.find(:all, :conditions => {:pathname => url.join("/"), :rank => 1..RCMS_MAX_BANNER}, :order => "rank")
    session[:banner] = g.default
    return g
  end

  def self.edit_refresh(id, url, session)
  # initialize instance variables @banner_url, @banner_uploads, and @banner_text for site controller edit_refresh definition
    b = {"url" => url.dup, "text" => 'Edit banners'}
    b.default = session[:banner]
    return b  
  end
  
  def self.create(fname, funique, url, session)
    return create_full(fname, funique, url, session[:banner], RCMS_MAX_BANNER)
  end
  
  def self.update_rjs(session)
  # called to refresh appropriate part of page after closing iframe in edit mode
    s = {"url" => session[:url]}
    s.default = session[:banner]
    return s
  end


end
