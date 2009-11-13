class Layout < ActiveRecord::Base

  has_many :pages
  
    def unique
    return false if Layout.find(:first,
      :conditions => ["name = ?", self.name])
    return true
  end

  def self.show(id, info)
    # initialize instance variables form and cur_form for site controller show definition
    f = {}
    if id == nil
      f.default = nil
      f["name"] = nil
    else
      begin
        f.default = Layout.find(id)
      rescue ActiveRecord::RecordNotFound
        f.default = nil
        f["name"] = nil
      else
        f["name"] = f.default.name
      end
    end
    return f
  end

  def self.edit(page, url, session)
    f = {}
    if page.layout_id == nil
      f.default = nil
      f["name"] = RCMS_LAYOUT_DEFAULT
    else
      begin
        f.default = Layout.find(page.layout_id)
      rescue ActiveRecord::RecordNotFound
        f.default = nil
        f["name"] = RCMS_LAYOUT_DEFAULT
      else
        f["name"] = f.default.name
      end
    end 
    f["url"] = url.dup
    session[:layout] = f["name"]
    return f
  end   
  
  def self.edit_refresh(id, url, session)
  # initialize instance variables @layout, @layout_url, and @cur_layout for site controller edit_refresh definition
    f = {"url" => url.dup, "name" => session[:layout]}
    if id == nil
      f.default = nil
    else
      begin
        f.default = Layout.find(id)
      rescue ActiveRecord::RecordNotFound
        f.default = nil
      end
    end  
    return f
  end
  
  def self.create(fname, funique, url, session)
  # initialize instance variables @form for site controller create definition
    f = {}
    if session[:layout] != nil
      f.default = Layout.new
      f.default.name = session[:layout]
      if f.default.unique
        f.default.save!
      else
        f.default = Layout.find(:first,
          :conditions => ["name = ?", f.default.name])
      end
    else
      f.default = nil
    end
    return f
  end

end
