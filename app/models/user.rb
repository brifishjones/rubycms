require 'net/ldap'
require 'user_ldap'     # user_ldap.rb contains module: RcmsUserLDAP

class User < ActiveRecord::Base
# User class contains users present in ldap as well as localusers.  Users are added to list when they log in.

  has_many :pages
  #validates_presence_of :user_name
  #validate_uniqueness_of :user_name
  #validates_confirmation_of :password
  validates_format_of :name,
                      :with => /^[A-Za-z0-9]+$/,
                      :message => "is invalid (may only contain letters or numbers)."
  validates_uniqueness_of :name,
                          :on => :create,
                          :message => "is already in use."
                          
  include RcmsUserLDAP
  
  def self.authenticate(username, password)
    RcmsUserLDAP.authenticate(username, password)
  end
  
  def unique
    return false if User.find(:first,
      :conditions => ["name = ?", self.name])
    return true
  end

  def privileged(filename, published)
    # confirm user has necessary privileges before edited page is submitted for review or is published
    # returns an array [true or false, message]
    wp = published == '1' ? "publish" : "write"
    wppt = published == '1' ? "published" : "written"
    filename.sub!(/^\/+/, "")

    # if user is administrator all privileges granted
    return true, "/" + filename + " successfully " + wppt + "." if Administrator.find(:first, :conditions => ["name = ?", self.name])

    privs = Privilege.find(:all)
    for p in privs do
      if filename =~ Regexp.new(p.regex)
        if p.user_publish_list != nil
          p.user_publish_list.split.each do |u|
            if u == "*" || self.id == u.to_i
              return true, "/" + filename + " successfully " + wppt + "."
            end
          end
        end
        if p.group_publish_list != nil
          p.group_publish_list.split.each do |u|
            return true, "/" + filename + " successfully " + wppt + "." if User.member_of_ldap_group(self.name, u)
          end
        end
        if wp == "write"
          if p.user_write_list != nil
            p.user_write_list.split.each do |u|
              if u == "*" || self.id == u.to_i
                return true, "/" + filename + " successfully " + wppt + "."
              end
            end
          end
          if p.group_write_list != nil
            p.group_write_list.split.each do |u|
              return true, "/" + filename + " successfully " + wppt + "." if User.member_of_ldap_group(self.name, u)
            end
          end
        end
      end
    end

    # allow user to publish into "home" directory, that being community/<username>
    if filename =~ Regexp.new("^\/?community\/" + self.name + "(.*)")
      return true, "/" + filename + " successfully " + wppt + "."
    end
  
    return false, "You do not have permissions to " + wp + " /" + filename
   
  end

end
