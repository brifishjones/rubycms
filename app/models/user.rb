require 'net/ldap'

class User < ActiveRecord::Base
# User class contains users present in ldap as well as localusers.  Users are added to list when they log in.
# Modify this file when setting up ldap connection.
# In particular the following methods will need attention:
#   authenticate
#   exists_in_ldap
#   group_exists_in_ldap
#   member_of_ldap_group

  # set @@using_ldap to true when ldap is configured
  @@using_ldap = false
   
  @@ldap_host = 'rubycms.org'
  @@ldap_port = 389
  @@ldap_base = 'dc=rubycms,dc=org'

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
  
  def self.authenticate(username, password)
    return false if !@@using_ldap
    ldap = Net::LDAP.new(:host => @@ldap_host, :port => @@ldap_port, :base => @@ldap_base)
    filter = Net::LDAP::Filter.eq('uid', username)
    ldap.search(:filter => filter) {|entry| username = entry.dn}
    ldap.auth(username, password)
    return true if ldap.bind
    return false
  end
  
  def exists_in_ldap
    return false if !@@using_ldap
    ldap = Net::LDAP.new(:host => @@ldap_host, :port => @@ldap_port, :base => @@ldap_base)
    filter = Net::LDAP::Filter.eq('uid', self.name)
    ui = self.name
    ldap.search(:filter => filter) {|entry| ui = entry.dn}
    return false if !ui.include?("uid=" + self.name + ",ou=People," + @@ldap_base)
    return true 
  end
  
  def group_exists_in_ldap(group)
    return false if !@@using_ldap
    ldap = Net::LDAP.new(:host => @@ldap_host, :port => @@ldap_port, :base => @@ldap_base)
    filter = Net::LDAP::Filter.eq('cn', group)
    ldap.search(:filter => filter) do |entry| 
      return true if entry.dn.include?("cn=" + group + ",ou=Group," + @@ldap_base)
    end
    return false
  end

  def self.member_of_ldap_group(username, group)
    return false if !@@using_ldap
    return false if username == nil || group == nil
    ldap = Net::LDAP.new(:host => @@ldap_host, :port => @@ldap_port, :base => @@ldap_base)
    filter = Net::LDAP::Filter.eq('cn', group) & Net::LDAP::Filter.eq('memberUid', username)
    ldap.search(:filter => filter, :attributes => "memberUid") do |entry|
      return true if entry.memberuid.include?(username)
    end
  return false
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

    # if user is administrator all privileges granted
    return true, filename + " successfully " + wppt + "." if Administrator.find(:first, :conditions => ["name = ?", self.name])

    privs = Privilege.find(:all)
    for p in privs do
      if filename =~ Regexp.new(p.regex)
        if p.user_publish_list != nil
          p.user_publish_list.split.each do |u|
            if u == "*" || self.id == u.to_i
              return true, filename + " successfully " + wppt + "."
            end
          end
        end
        if p.group_publish_list != nil
          p.group_publish_list.split.each do |u|
            return true, filename + " successfully " + wppt + "." if User.member_of_ldap_group(self.name, u)
          end
        end
        if wp == "write"
          if p.user_write_list != nil
            p.user_write_list.split.each do |u|
              if u == "*" || self.id == u.to_i
                return true, filename + " successfully " + wppt + "."
              end
            end
          end
          if p.group_write_list != nil
            p.group_write_list.split.each do |u|
              return true, filename + " successfully " + wppt + "." if User.member_of_ldap_group(self.name, u)
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
