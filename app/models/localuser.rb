require 'encrypter'

class Localuser < ActiveRecord::Base

  validates_format_of :name,
                      :with => /^[A-Za-z0-9]+$/,
                      :message => "is invalid (may only contain letters or numbers)."
  validates_uniqueness_of :name,
                          :on => :create,
                          :message => "is already in use."
                          
  encrypt(:password)
  
  def self.authenticate(username, password)
    lu = Localuser.find(:first,
        :conditions => ["name = ?", username])
    if lu != nil
      return true if lu.password == password
    end
    return false
  end
  
  def privileged(filename, published)
    # confirm local user has necessary privileges before edited page is submitted for review or is published
    # returns an array [true or false, message]
    wp = published == '1' ? "publish" : "write"
    wppt = published == '1' ? "published" : "written"
    
    # if user is administrator all privileges granted
    return true, filename + " successfully " + wppt + "." if Administrator.find(:first, :conditions => ["name = ?", self.name])

    privs = Privilege.find(:all)
    for p in privs do
      if filename =~ Regexp.new(p.regex)
        if p.user_publish_list != nil
          p.user_publish_list.split.each do |u|
            if self.id == u.to_i
              return true, filename + " successfully " + wppt + "."
            end
          end
        end
        if wp == "write"
          if p.user_write_list != nil
            p.user_write_list.split.each do |u|
              if self.id == u.to_i
                return true, filename + " successfully " + wppt + "."
              end
            end
          end
        end
      end
    end
  
    # allow user to publish into "home" directory, that being community/<username>
    if filename =~ Regexp.new("^\/?community\/" + self.name + "(.*)")
      return true, filename + " successfully " + wppt + "."
    end
  
    return false, "You do not have permissions to " + wp + " " + filename
   
  end

end
