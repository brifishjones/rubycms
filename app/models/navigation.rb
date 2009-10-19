class Navigation < ActiveRecord::Base

  has_many :pages
  
  def unique
    n = Navigation.find(:first,
      :conditions => ["list = ?", self.list])
    return false if n != nil && self.href_list == n.href_list
    return true
  end
  
  def self.show(id, info)
  # initialize instance variables @navigation, @nav_list, and @cur_navlist_item for site controller show definition
    n = {}
    if id == nil
      n.default = Navigation.new
      n.default.list = ''
      n.default.href_list = ''
    else
      begin
        n.default = Navigation.find(id)
      rescue ActiveRecord::RecordNotFound
        n.default = Navigation.new
        n.default.list = ''
        n.default.href_list = '' 
      end
    end
    n["list"] = Navlist.new(n.default)
    n["current"] = nil
    return n
  end

  def self.edit(page, url, session)
  # initialize instance variables @navigation.default, @navigation["list"], and @navigation["current"] for site controller edit definition
    n = {}
    if page.navigation_id == nil
      n.default = Navigation.new
      n.default.list = ''
      n.default.href_list = ''  
    else
      n.default = Navigation.find(page.navigation_id)
    end
    n["list"] = Navlist.new(n.default)
    session[:nav_list] = Navlist.new(n.default)
    n["current"] = nil
    return n
  end
  
  def self.edit_refresh(id, url, session)
  # initialize instance variables @navigation, @nav_list, and @cur_navlist_item for site controller edit_refresh definition
    n = {"list" => session[:nav_list], "current" => nil}
    if id == nil
      n.default = nil
    else
      begin
        n.default = Navigation.find(id)
      rescue ActiveRecord::RecordNotFound
        n.default = nil
      end
    end
    return n
  end

  def self.create(session)
  # initialize instance variable @nav_list and new navigation for site controller create definition
    n = {"list" => session[:nav_list]}
    if n["list"] != nil && n["list"].nav_list.size > 0
      n.default = Navigation.new
      names = []
      hrefs = []
      n["list"].nav_list.each_index do |i|
        names << n["list"].nav_list[i].name
        hrefs << n["list"].nav_list[i].href
      end
      n.default.list = names.join('=(_8^(1)')
      n.default.href_list = hrefs.join(' ')
      if n.default.unique   
        n.default.save!
      else
        n.default = Navigation.find(:first,
          :conditions => ["list = ?", n.default.list])
      end
    end
    return n
  end

end
