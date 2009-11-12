class Rubycms::NavigationController < ApplicationController
# alters navigation on main page not in separate iframe
 
  def set_to_edit_mode
    @navigation = {"current" => params[:cur_navlist_item], "list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end

  def order_navlist   
    @navigation = {"current" => params[:cur_navlist_item], "list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
 
    names = []
    hrefs = []
    @navigation["list"].nav_list.each_index do |i|
      names << @navigation["list"].nav_list[i].name
      hrefs << @navigation["list"].nav_list[i].href
    end

    item_set = false
    item_set = true if @navigation["current"] == nil 
    params[:navlist].each_index do |i|
      @navigation["list"].nav_list[i].name = names[params[:navlist][i].to_i]
      @navigation["list"].nav_list[i].href = hrefs[params[:navlist][i].to_i]
      if item_set == false && @navigation["current"].to_i == params[:navlist][i].to_i
        @navigation["current"] = i
        item_set = true
      end
    end  
    session[:navigation] = @navigation["list"]
    render :partial => '/site/navigation'
  end

  def update_navlist
    @navigation = {"current" => params[:cur_navlist_item], "list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    
    if (@navigation["current"].to_i == @navigation["list"].nav_list.size.to_i)
      if (params[:name] != '(Enter link name)' || params[:href] != '(Enter link url)')
        @navigation["list"].add(params[:name], params[:href])
      end
    else
      @navigation["list"].nav_list[@navigation["current"].to_i].name = params[:name]
      @navigation["list"].nav_list[@navigation["current"].to_i].href = params[:href]
    end
    session[:navigation] = @navigation["list"]
    @navigation["current"] = nil
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end

  def refresh_navlist
    @navigation = {"current" => nil, "list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end
   
  def add_to_navlist   
    @navigation = {"list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    @navigation["current"] = @navigation["list"] != nil ? @navigation["list"].nav_list.size : nil
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end

  def import_navlist
    @navigation = {"current" => nil, "list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    @import_navlist = true
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end

  def replace_navlist
  # called when OK button is pressed--imports a navlist from an existing page
    @navigation = {}
    @page = Page.find(params[:page])
    @filename = Filename.find(@page.filename_id)
    importpage = Page.find_page(params[:importpath].gsub(/^\//, "")) 
    if importpage == nil || importpage.navigation_id == nil
      #flash[:notice] = 'Navigation not imported.'
      @navigation["list"] = session[:navigation]
    else  
      @navigation.default = Navigation.find(importpage.navigation_id)
      @navigation["list"] = Navlist.new(@navigation.default)
      session[:navigation] = Navlist.new(@navigation.default)
    end
    @navigation["current"] = nil
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end

  def revert_navlist
    @navigation = {}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    if @page.navigation_id == nil
      @navigation.default = Navigation.new
      @navigation.default.list = ''
      @navigation.default.href_list = ''  
    else
      @navigation.default = Navigation.find(@page.navigation_id)
    end
    @navigation["list"] = Navlist.new(@navigation.default)
    session[:navigation] = Navlist.new(@navigation.default)
    @navigation["current"] = nil
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end 
  end 
  
  def delete_from_navlist   
    @navigation = {"current" => params[:cur_navlist_item], "list" => session[:navigation]}
    @page = Page.find(params[:page])  
    @filename = Filename.find(@page.filename_id)
    @navigation["list"].nav_list.delete_at(@navigation["current"].to_i) 
    session[:navigation] = @navigation["list"]
    @navigation["item"] = nil
    render :update do |page|
      page.replace_html("nav", :partial => "site/navigation")
    end
  end

end
