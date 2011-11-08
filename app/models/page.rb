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
  
  def has_children?()
    u = Filename.find(:first,
      :conditions => ["name like ?", self.filename.name + "/%"])
    return u != nil ? true : false
  end
  
  def clean_content_before_save
    return if self.content == nil
    
    # clean up images that were dragged into tinyMCE content editor before writing to database
    # tiny will insert relative paths when images are dragged in content area
    self.content.gsub!(/(<a href="\/\S+">)(<img src="[\.\/]*?\S+").*?\/>.*?<\/a>/, '\1' + '\2' + ' /></a>') 
    self.content.gsub!(/(<a href=")[\.\/]*(\S+"><img src=")[\.\/]*(\S+").*?\/>.*?<\/a>/, '\1/\2/\3 /></a>')
    self.content.gsub!(/(<a href=")\/(https?:\/\/www\.youtube\.com\/v\/)/, '\1\2')
    self.content.gsub!(/(<img src=")\/(https?:\/\/i3.ytimg.com\/vi\/)/, '\1\2')
  end
  
  def add_captions_when_editing(pathname)
    return if self.content == nil
    # add caption to the image title field
    # note that titles will only appear on image hovers after a page has been saved.
    # any changes to the caption during editing using the Image and Document Manager will not propagate to the tinyMCE editor.
    # odK8H1TG6gkqI0Vt is a randomly generated string
    
    image_uploads = Image.find(:all, :conditions => {:pathname => pathname})
    for img in image_uploads
      basename = File.basename(img.public_filename, ".*")
      # make any hidden images visible again if they are referenced in page content
      if self.content =~ Regexp.new('(/images/)(' + CGI.escape(img.pathname) + '/)(' + basename + ')') && img.caption =~ /^HIDEe584f2e1ed91IMAGE/     
        img.caption = img.caption.gsub("HIDEe584f2e1ed91IMAGE", "")
        img.save
      end
    end
    
    file_uploads = Fileupload.find(:all, :conditions => {:pathname => pathname})
    for d in file_uploads
      # make any hidden files visible again if they are referenced in page content
      if self.content =~ Regexp.new('(/files/)(' + CGI.escape(d.pathname) + '/)(' + d.filename.gsub("HIDEm4afK6RpFILE", "") + ')') && d.filename =~ /^HIDEm4afK6RpFILE/     
        d.filename = d.filename.gsub("HIDEm4afK6RpFILE", "")
        d.save
      end
    end
      
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
    self.content.gsub!(/(<a href="\S+")>(<img src="\S+_\w+Ex\.\w+")\s?\/><\/a>/, '<span class="figure" style="width: XiLU6h3xB7r4NyzVpx">' + '\1' + ' class="highslide" onclick="return hs.expand(this)">' + '\2' + ' alt="XiLU6h3xB7r4NyzV" title="Click to enlarge" /></a>' + 'XiLU6h3xB7r4NyzV</span>')

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
      
      begin
        img = Magick::Image.read('public' + CGI.unescape(j.to_s)).first
      rescue
        self.content.sub!(/<span class="figure" style="width: XiLU6h3xB7r4NyzVpx">.*?XiLU6h3xB7r4NyzV<\/span>/, "")
      else
        self.content.sub!(/(<span class="figure" style="width: )(XiLU6h3xB7r4NyzV)(px">)/, '\1' + img.columns.to_s + '\3')
        filename = File.basename(j.to_s).sub(/(\S+)(_\w+Ex)(\.\w+)/, '\1' + '\3')
        
        imgfile = Image.find(:first, :conditions => ["filename = ? and pathname = ?", filename, self.filename.name])
        
        if self.imageinfo != nil && self.imageinfo != "" && imgfile != nil && image_hash[imgfile.id] != ""
          self.content.sub!(/(alt=")(XiLU6h3xB7r4NyzV)(")/, '\1' + image_hash[imgfile.id].to_s + '\3')
          self.content.sub!(/(XiLU6h3xB7r4NyzV)(<\/span>)/, image_hash[imgfile.id].to_s + '\2')
        elsif (self.imageinfo == nil || self.imageinfo == "") && imgfile != nil && imgfile.caption != nil
          self.content.sub!(/(alt=")(XiLU6h3xB7r4NyzV)(")/, '\1' + imgfile.caption + '\3')
          self.content.sub!(/(XiLU6h3xB7r4NyzV)(<\/span>)/, imgfile.caption + '\2')
        else
          self.content.sub!(/(alt=")(XiLU6h3xB7r4NyzV)(")/, '')
          self.content.sub!(/(XiLU6h3xB7r4NyzV)(<\/span>)/, '\2')
        end
        # uncomment destroy! when newer ImageMagick rpm released on server
        #t.destroy!  #important to free memory because Rmagick doesn't do it automatically.
        self.full_size_image if self.filename.name =~ /^\/?spotlights\//
      end
    end
  end
  
  def format_video
    return if self.content == nil
    i = self.content.scan(/(<a href="https?:\/\/www\.youtube\.com\/v\/)([\w-]+).*?w=(\d+).*?h=(\d+)">(<img src="https?:\/\/i3\.ytimg\.com\/vi\/[\w-]+\/default.jpg").*?\/><\/a>/)
    i.each do |j|
      if j != nil && j[0] != nil && j[1] != nil && j[2] != nil && j[3] != nil && j[4] != nil
        self.content.sub!(/(<a href="https?:\/\/www\.youtube\.com\/v\/)([\w-]+).*?w=(\d+).*?h=(\d+)">(<img src="https?:\/\/i3\.ytimg\.com\/vi\/[\w-]+\/default.jpg").*?\/><\/a>/,
          #'<span><div class="figure" style="width: 120px">' + j[0] + j[1] + '&hl=en&rel=0&fs=0&autoplay=1" onclick="return hs.htmlExpand(this, { objectType: \'swf\', width: ' + j[2] + ', objectWidth: ' + j[2] + ', objectHeight: ' + j[3] + ', preserveContent: false, outlineType: \'rounded-white\', wrapperClassName: \'draggable-header no-footer\', maincontentText: \'You need to upgrade your Flash player\', swfOptions: { version: \'7\' } })" class="highslide">' + j[4] + ' /><img class="av-play" title="Click to play video" src="/images/play_44.png" /></a>' + add_captions_to_video(j[1]) + '</div></span>')  
     '<span class="figure" style="width: 120px">' + j[0] + j[1] + '&hl=en&rel=0&fs=0&autoplay=1" onclick="return hs.htmlExpand(this, { objectType: \'swf\', width: ' + j[2] + ', objectWidth: ' + j[2] + ', objectHeight: ' + j[3] + ', preserveContent: false, outlineType: \'rounded-white\', wrapperClassName: \'draggable-header no-footer\', maincontentText: \'You need to upgrade your Flash player\', swfOptions: { version: \'7\' } })" class="highslide">' + j[4] + ' /><img class="av-play" title="Click to play video" src="/images/play_44.png" /></a>' + add_captions_to_video(j[1]) + '</span>')  

      end
    end
    
    #self.content.gsub!(/(<a href="https?:\/\/www\.youtube\.com\/v\/)([\w-]+).*?w=(\d+).*?h=(\d+)">(<img src="https?:\/\/i3\.ytimg\.com\/vi\/[\w-]+\/default.jpg").*?\/><\/a>/,
    #  '<span><div class="figure">\1\2&hl=en&rel=0&fs=0&autoplay=1" onclick="return hs.htmlExpand(this, { objectType: \'swf\', width: \3, objectWidth: \3, objectHeight: \4, preserveContent: false, outlineType: \'rounded-white\', wrapperClassName: \'draggable-header no-footer\', maincontentText: \'You need to upgrade your Flash player\', swfOptions: { version: \'7\' } })" class="highslide">\5 /><img class="av-play" title="Click to play video" src="/images/play_44.png" /></a>' + '' + '</div></span>')
     
      #<img class=\"av-play\" title=\"Play Video: " . $item->get_value( 'name' ) . "\" src=\"/images/play_44.png\" /></a>

  end

  def add_captions_to_video(id)
  # finds youtube video based on id and returns the video title
    # http://code.whytheluckystiff.net/hpricot/
    require 'hpricot'
    require 'open-uri'
    url = "http://www.youtube.com/watch?v=" + id
    f = Hpricot(open(url), :fixup_tags => true)
    title = (f/"title")
    #return (title[0].inner_html).sub!(/^\s*YouTube\s*-\s*(\w.*?\w)\s*/, '\1')
    return title[0] != nil ? (title[0].inner_html).sub(/^\s*YouTube\s*-\s*/, '') : ''
    
  end
  
  def keyword_match(fkey)
  # returns true or false based on keyword existence or if keywords match
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
      return false if Time.now > valid_to
    elsif valid_to == nil 
      return false if Time.now < valid_from
    end
    return true
  end
  
  def full_size_image
    # for spotlights use full-size image and disable highslide
    self.content.sub!(/(<div class="figure" style="width.*?class="highslide" onclick="return hs.expand\(this\)".*?)(<img.*?src="\S+\/\w+)(_\w+Ex)(\.\w+").*?(\/>\s?<\/a>\s?<\/div>)/, '<div class="figure"> ' + '\2' + '\4' + '\5')
  end

end
