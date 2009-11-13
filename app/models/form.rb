class Form < ActiveRecord::Base

  has_many :pages
  
  def unique
    return false if Form.find(:first,
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
        f.default = Form.find(id)
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
    if page.form_id == nil
      f.default = nil
      f["name"] = nil
    else
      begin
        f.default = Form.find(page.form_id)
      rescue ActiveRecord::RecordNotFound
        f.default = nil
        f["name"] = nil
      else
        f["name"] = f.default.name
      end
    end 
    f["url"] = url.dup
    session[:form] = f["name"]
    return f
  end
  
  def self.edit_refresh(id, url, session)
  # initialize instance variables @form, @form_url, and @cur_form for site controller edit_refresh definition
    f = {"url" => url.dup, "name" => session[:form]}
    if id == nil
      f.default = nil
    else
      begin
        f.default = Form.find(id)
      rescue ActiveRecord::RecordNotFound
        f.default = nil
      end
    end  
    return f
  end
  
  def self.update_rjs(session)
  # called to refresh appropriate part of page after closing iframe in edit mode
    return {"url" => session[:url], "name" => session[:form]}
  end
  
  def self.create(fname, funique, url, session)
  # initialize instance variables @form for site controller create definition
    f = {}
    if session[:form] != nil
      f.default = Form.new
      f.default.name = session[:form]
      if f.default.unique
        f.default.save!
      else
        f.default = Form.find(:first,
          :conditions => ["name = ?", f.default.name])
      end
    else
      f.default = nil
    end
    return f
  end

end
