class Page < ActiveRecord::Base

  belongs_to :banner
  belongs_to :contact
  belongs_to :imagetop
  belongs_to :imageside
  belongs_to :layout
  belongs_to :navigation
  belongs_to :form
  belongs_to :robot
  belongs_to :gallery
  belongs_to :subscription
  belongs_to :filename
  belongs_to :user
  belongs_to :keyword
  
  #def validate
  #  errors.add(:published, "You don't have privileges to publish to this location")
  #end
  
  #validates_format_of :title,
  #                    :with => /^Hello World$/,
  #                    :message => "invalid title"
  
  def self.find_page(filename)
    u = Filename.find(:first,
      :conditions => ["name = ?", filename])
    if u != nil
      p = Page.find(:all,
        :order => 'modified DESC',
        :conditions => ["filename_id = ?", u.id])
      return p[0]
    end  
  end
  
  def self.find_published(filename)
    u = Filename.find(:first,
      :conditions => ["name = ?", filename])
    if u != nil
      p = Page.find(:all,
        :order => 'modified DESC',
        :conditions => ["filename_id = ? and published = ?", u.id, true])
        #:conditions => ["filename_id = ? and published = '1'", u.id])
      return p[0]
    end  
  end
  
  def clean_content_before_save
    return if self.content == nil
    
    # clean up images that were dragged into tinyMCE content editor before writing to database
    self.content.gsub!(/(<a href="\/\S+">)(<img src="[\.\/]*?\S+").*?\/>.*?<\/a>/, '\1' + '\2' + ' /></a>') 
  end
  
  def add_captions_when_editing(pathname)
    return if self.content == nil
    # add caption to the image title field
    # note that titles will only appear on image hovers after a page has been saved.
    # any changes to the caption during editing using the Image and Document Manager will not propagate to the tinyMCE editor.
    # odK8H1TG6gkqI0Vt is a randomly generated string
    self.content.gsub!(/(<a href="\S+"><img src="\S+_\w+Ex\.\w+")\s?\/><\/a>/, '\1' + ' title="odK8H1TG6gkqI0Vt" /></a>')

    image_hash = {}
    if self.imageinfo != nil && self.imageinfo != ""
    imgi = self.imageinfo.split('=(_8^(1)')
      0.upto(imgi.size - 1) do |i|
        a = imgi[i].split('@@@@8^)')
        image_hash[a[0].to_i] = a.size == 2 ? a[1] : ""
      end
    end
    
    i = self.content.scan(/<img src="(\S+_\w+Ex\.\w+)"/)
    i.each do |j|
      filename = File.basename(j.to_s).sub(/(\S+)(_\w+Ex)(\.\w+)/, '\1' + '\3')
      imgfile = Image.find(:first, :conditions => ["filename = ? and pathname = ?", filename, self.filename.name])
      if self.imageinfo != nil && self.imageinfo != "" && imgfile != nil && image_hash[imgfile.id] != ""
        self.content.sub!(/(title=")(odK8H1TG6gkqI0Vt)(")/, '\1' + image_hash[imgfile.id].to_s + '\3')
      elsif (self.imageinfo == nil || self.imageinfo == "") && imgfile != nil && imgfile.caption != nil
        self.content.sub!(/(title=")(odK8H1TG6gkqI0Vt)(")/, '\1' + imgfile.caption + '\3') 
      else
        self.content.sub!(/(title=")(odK8H1TG6gkqI0Vt)(")/, '')
      end
    end
    
  end
  
  def add_captions_to_images
    return if self.content == nil
    require 'RMagick'
    # XiLU6h3xB7r4NyzV is a randomly generated string
    self.content.gsub!(/(<a href="\S+")>(<img src="\S+_\w+Ex\.\w+")\s?\/><\/a>/, '<span><div class="figure" style="width: XiLU6h3xB7r4NyzVpx">' + '\1' + ' class="highslide" onclick="return hs.expand(this)">' + '\2' + ' alt="XiLU6h3xB7r4NyzV" title="Click to enlarge" /></a>' + 'XiLU6h3xB7r4NyzV</div></span>')

    image_hash = {}
    if self.imageinfo != nil && self.imageinfo != ""
    imgi = self.imageinfo.split('=(_8^(1)')
      0.upto(imgi.size - 1) do |i|
        a = imgi[i].split('@@@@8^)')
        #g = Image.find(a[0])
        #g.caption = a.size == 2 ? a[1] : ""
        #image_uploads << g
        #flash[:notice] << g.id.to_s
        image_hash[a[0].to_i] = a.size == 2 ? a[1] : ""
      end
    end
    
    i = self.content.scan(/<img src="(\S+_\w+Ex\.\w+)"/)
    i.each do |j|
      img = Magick::Image.read('public' + j.to_s).first
      self.content.sub!(/(<span><div class="figure" style="width: )(XiLU6h3xB7r4NyzV)(px">)/, '\1' + img.columns.to_s + '\3')
      filename = File.basename(j.to_s).sub(/(\S+)(_\w+Ex)(\.\w+)/, '\1' + '\3')
      
      imgfile = Image.find(:first, :conditions => ["filename = ? and pathname = ?", filename, self.filename.name])
      
      if self.imageinfo != nil && self.imageinfo != "" && imgfile != nil && image_hash[imgfile.id] != ""
        self.content.sub!(/(alt=")(XiLU6h3xB7r4NyzV)(")/, '\1' + image_hash[imgfile.id].to_s + '\3')
        self.content.sub!(/(XiLU6h3xB7r4NyzV)(<\/div>)/, image_hash[imgfile.id].to_s + '\2')
      elsif (self.imageinfo == nil || self.imageinfo == "") && imgfile != nil && imgfile.caption != nil
        self.content.sub!(/(alt=")(XiLU6h3xB7r4NyzV)(")/, '\1' + imgfile.caption + '\3')
        self.content.sub!(/(XiLU6h3xB7r4NyzV)(<\/div>)/, imgfile.caption + '\2')
      else
        self.content.sub!(/(alt=")(XiLU6h3xB7r4NyzV)(")/, '')
        self.content.sub!(/(XiLU6h3xB7r4NyzV)(<\/div>)/, '\2')
      end
      # uncomment destroy! when newer ImageMagick rpm released on server
      #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
      self.full_size_image if self.filename.name =~ /^\/?spotlights\//
    end
  end
  
  def keyword_match(fkey)
  # returns true or false based on keyword existance or if keywords match
    return true if self.keyword == nil || self.keyword.list == ''
    return false if fkey == nil || fkey.list == ''
    return true if self.keyword.list.split & fkey.list.split
    return false
  end
  
  def page_valid(valid_from, valid_to)
  # determine if page has expired or is valid at a future date.
  # return true or false
    valid_from = nil if valid_from == ''
    valid_to = nil if valid_to == ''
    return true if valid_from == nil && valid_to == nil
    
    if valid_from == nil
      return false if Time.now > Time.valid_to
    elsif valid_to == nil 
      return false if Time.now < Time.valid_from
    end
    return true
  end
  
  def full_size_image
    # for spotlights use full-size image and disable highslide
    self.content.sub!(/(<div class="figure" style="width.*?class="highslide" onclick="return hs.expand\(this\)".*?)(<img.*?src="\S+\/\w+)(_\w+Ex)(\.\w+").*?(\/>\s?<\/a>\s?<\/div>)/, '<div class="figure"> ' + '\2' + '\4' + '\5')
  end
  
  def make_current
  # transfers imageinfo, imagetopinfo, bannerinfo, imagesideinfo, and galleryinfo from this page instance
  # to the appropriate model for a given filename.
  # called when a previous version of a page is made current.
  
    # images
    Image.make_info_current(self)
  
    # top image
    Imagetop.make_info_current(self)
    
    # banner
    Banner.make_info_current(self, self.bannerinfo)
    
    # side image
    Imageside.make_info_current(self, self.imagesideinfo)
    
    # gallery
    Gallery.make_info_current(self)
  end

end
