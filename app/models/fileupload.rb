require 'model_helper'     # lib/model_helper.rb contains modules: RcmsModel and AttachmentFuModel

class Fileupload < ActiveRecord::Base

  has_attachment :content_type => ['application/pdf', 'application/x-pdf', 'application/msword', 'text/rtf', 'text/plain', 'application/x-shockwave-flash', 'application/octet-stream'],
                 :storage => :file_system, 
                 :max_size => RCMS_MAX_DOCUMENT_SIZE,
                 :path_prefix => 'public/system/files'
                 
  validates_as_attachment
  
  include AttachmentFuModel
  class << self
    include RcmsModel
  end

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

  def self.create(page, filename, funique, url, session)
  # initialize instance variable @file_upload for site controller create definition
    file_uploads = Fileupload.find(:all, :conditions => {:pathname => url})
    if funique == true
      # copy documents used in content
      for d in file_uploads  
        if page.content =~ Regexp.new('(/files/)(' + d.pathname + '/)(' + d.filename + ')')
          if File.exist?("#{RAILS_ROOT}/public" + d.public_filename)
            fd = File.open("#{RAILS_ROOT}/public" + d.public_filename, "rb").read
            m = Fileupload.new(:file_data => fd)
            m.filename = d.filename
            m.pathname = filename.name
            m.content_type = d.content_type
            m.attachment_options[:path_prefix] = d.attachment_options[:path_prefix]
            m.save
            page.content.gsub!("#{$1}#{$2}#{$3}", "#{$1}" + m.pathname + "/" + "#{$3}")
          end
        end
      end
    end 
    g = {}
    g.default = file_uploads
    g["content"] = page.content
    return g
  end

end
