class Contact < ActiveRecord::Base

  has_many :pages
  
  def self.options_edit
    return '@page.contact_id, params[:url], session'
  end
  
  def unique
    c = Contact.find(:first,
      :conditions => ["list = ?", self.list])
    return false if c != nil && self.hide == c.hide
    return true
  end

  def self.show(id, info)
    # initialize instance variables @contact.default, @contact["list"], and @contact["hide"] for site controller show definition
    c = {"list" => nil, "hide" => false}
    return c if id == nil
    begin
      contact = Contact.find(id)
    rescue ActiveRecord::RecordNotFound
      return c
    else
      c.default = contact
      c["list"] = Clist.new(contact)
      c["hide"] = contact.hide
      return c
    end
  end

  def self.edit(page, url, session)
    # initialize instance variables @contact["url"], @contact["list"], and @contact["hide"] for site controller edit definition
      c = {"url" => url.dup}
      if page.contact_id == nil
        c.default = nil
        c["list"] = nil
        session[:contact_list] = nil
        c["hide"] = false
        session[:contact_hide] = false
      else
        c.default = Contact.find(page.contact_id) 
        c["list"] = Clist.new(c.default)
        session[:contact_list] = Clist.new(c.default)
        if c.default.hide == false
          c["hide"] = false
        else
          c["hide"] = true 
        end
        session[:contact_hide] = c["hide"]
      end
    return c
  end

  def self.edit_refresh(id, url, session)
  # initialize instance variables @contact["url"], @contact["list"], and @contact["hide"] for site controller edit_refresh definition
    return {"url" => url.dup, "list" => session[:contact_list], "hide" => session[:contact_hide]}
  end

  def self.create(session)
  # initialize instance variable @contact_list and new contact for site controller create definition
    c = {"list" => session[:contact_list]}
    if c["list"] != nil
      c.default = Contact.new
      c.default.list = ''
      0.upto(c["list"].contact_list.size - 1) do |i|
        c.default.list << '=(_8^(1)' if i != 0
        c.default.list << c["list"].contact_list[i].join('\n')
      end
      c.default.hide = session[:contact_hide]
   
      if c.default.unique   
        c.default.save!
      else
        c.default = Contact.find(:first,
          :conditions => ["list = ?", c.default.list])
      end
    end
    return c
  end

end
