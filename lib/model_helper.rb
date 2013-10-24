module RcmsModel
# helper routines used by models dealing with images: gallery, banner, sidebar
# http://blog.martiandesigns.com/2008/04/29/monkeypatching-class-methods-in-rubyrails/#comments

  def full_filename(thumbnail = nil)  
    file_system_path = File.join(attachment_options[:path_prefix].to_s, "#{pathname}\/")    
    File.join(RAILS_ROOT, file_system_path, thumbnail_name_for(thumbnail))
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
    
  def file_data=(fd)
      return nil if fd.nil? || fd.size == 0
      set_temp_data(fd)
  end

  def show(id, info)
    # initialize instance variable hash (uploads) for site controller show definition
    h = {}
    uploads = []
    if info != nil && info != ""
      rank = 1
      # construct an array from page model info
      ui = info.split('=(_8^(1)')
      0.upto(ui.size - 1) do |i|
        a = ui[i].split('@@@@8^)') 
        begin
          b = self.find(a[0])
        rescue
          # skip if file not found
        else
          b.show = a.size >= 2 && a[1] != nil ? a[1] : ""
          b.caption = a.size >= 3 && a[2] != nil ? a[2] : ""
          (b.href = a.size >= 4 && a[3] != nil ? a[3] : "") if b.has_attribute?('href')
          b.rank = rank
          rank += 1
          uploads << b
        end
      end
    end
    h.default = uploads
    return h
  end

  def create_full(fname, funique, url, session, maxrange)
    # initialize instance variable hash (uploads and info) for a given model.  Used by site controller when a page is saved.
    uploads = session
    if funique == false
      ul = self.find(:all, :conditions => {:pathname => fname})
      for i in ul
        i.rank = 0   # initialize all to removed status
        uploads.each_index do |j|
          if i.id == uploads[j].id
            i.rank = j + 1
            uploads[j].rank = j + 1
            uploads[j].save
            break
          end
        end
        i.save if i.rank == 0
      end
    else
      rank = 1
      for i in uploads
        if i.show
          begin
            fd = File.open("#{RAILS_ROOT}/public" + i.public_filename, "rb").read
          rescue
            i.show = false
          else
            b = self.new(:file_data => fd)
            b.filename = i.filename
            b.pathname = fname
            b.rank = rank
            b.show = true
            b.href = i.href if b.has_attribute?('href')
            b.caption = i.caption
            b.content_type = i.content_type
            b.attachment_options[:path_prefix] = i.attachment_options[:path_prefix]
            mkdir_p(b.pathname)
            b.create_thumbnails() if b.save
            rank += 1
          end
        end
      end
    end
    uploads = nil
    
    # create info list
    il = self.find(:all, :conditions => {:pathname => fname, :rank => 1..maxrange}, :order => "rank") 
    ili = ""
    for i in il
      sh = i.show ? "1" : "0"
      ili << "=(_8^(1)" if ili != ""
      if i.has_attribute?('href')
        ili << i.id.to_s + "@@@@8^)" + sh + "@@@@8^)" + i.caption.to_s + "@@@@8^)" + i.href.to_s
      else
        ili << i.id.to_s + "@@@@8^)" + sh + "@@@@8^)" + i.caption.to_s
      end
    end
    g = {}
    g.default = uploads
    g["info"] = ili
    return g
    
  end
  
  def make_info_current(page)
  # Called when making a previous version current.  Updates current model for each item in page info
    mids = self.find(:all, :select => "id", :conditions => {:pathname => page.filename.name}, :order => "rank")
    return if mids == nil
      
    mid = []
    # construct an array of all ids found on this page for this model
    0.upto(mids.size - 1) do |i|
      mid << mids[i].id.to_s
    end
    
    #info = page[self.class.to_s.downcase + "info"]
    info = page[self.name.to_s.downcase + "info"]

    if info != nil && info != ""   
      # construct an array from page info
      pi = info.split("=(_8^(1)")
      rank = 1     
      0.upto(pi.size - 1) do |i|
        a = pi[i].split('@@@@8^)')
        begin
          b = self.find(a[0])
        rescue
          # skip if file not found
        else
          b.show = a[1] == "1" ? true : false
          b.caption = a[2] != nil ? a[2] : ""
          (b.href = a[3] != nil ? a[3] : "") if b.has_attribute?('href')
          b.rank = rank
          b.save
          rank += 1
          mid.delete(b.id.to_s)      # remove from id list
        end
      end
    end  

    # remaining ids will not be on list.  Set rank = 0
    0.upto(mid.size - 1) do |i|
      begin
        b = self.find(mid[i])
      rescue
          # skip if file not found
      else
        b.show = false
        b.rank = 0
        b.caption = ""
        b.href = "" if b.has_attribute?('href')
        b.save
      end
    end
  end
 
end

module AttachmentFuModel
# Methods used by attachment_fu plugin for a given model

  # Overwrite this method in model to customize the filename.
  def full_filename(thumbnail = nil)  
    file_system_path = File.join(attachment_options[:path_prefix].to_s, "#{pathname}\/")    
    File.join(RAILS_ROOT, file_system_path, thumbnail_name_for(thumbnail))
  end
  
  def file_data=(fd)
      return nil if fd.nil? || fd.size == 0
      set_temp_data(fd)
  end
  
end
