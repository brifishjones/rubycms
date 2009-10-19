class Rubycms::ContactController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @contact = {}
    if session[:contact_list] == nil
      session[:contact_list] = Clist.new(@contact.default)
      session[:contact_hide] = false
    end
    @contact["list"] = session[:contact_list]
    @contact["hide"] = session[:contact_hide]
  end 
  
  def update_contact_text_field
    @page = Page.find(params[:page])
    @section = params[:section]
    @line = params[:line]
    @contact = {"list" => session[:contact_list]}
    @contact["list"].contact_list[@section.to_i][@line.to_i] = params[:update_contact_text_field]
    session[:contact_list] = @contact["list"]
    render :partial => 'contact'
  end 
  
  def update_contact_hide
    @page = Page.find(params[:page])
    @contact = {"list" => session[:contact_list]}
    if params[:update_contact_hide] != '1'
      @contact["hide"] = false
    else
      @contact["hide"] = true
    end
    session[:contact_hide] = @contact["hide"]
    render :partial => 'contact'
  end
  
  def order_contact_sublist
    @page = Page.find(params[:page])
    @section = params[:section]
    @line = params[:line]
    @contact = {"list" => session[:contact_list]}   
    line_items = @contact["list"].contact_list[@section.to_i].dup   
    params['sublist_' + @section.to_s].each_index do |i|
      @contact["list"].contact_list[@section.to_i][i + 1] = line_items[params['sublist_' + @section.to_s][i].to_i]
    end
    session[:contact_list] = @contact["list"]
    render :partial => 'contact'  
  end
  
  def order_contact_sections
    @page = Page.find(params[:page])
    @contact = {"list" => session[:contact_list]}  
    sections = @contact["list"].contact_list.dup   
    params[:contactlist].each_index do |i|
      @contact["list"].contact_list[i + 1] = sections[params[:contactlist][i].to_i]
    end
    session[:contact_list] = @contact["list"]
    render :partial => 'contact' 
  end
  
  def add_section_to_contacts
    @page = Page.find(params[:page])
    @contact = {"list" => session[:contact_list]}
    @contact["list"].contact_list << Array.new(1, '')
    session[:contact_list] = @contact["list"]
    render :update do |page|
      page.replace_html("contactcap", :partial => "rubycms/contact/contact")
    end
  end
    
  def add_line_to_contacts
    @page = Page.find(params[:page])
    @section = params[:section]
    @contact = {"list" => session[:contact_list]}
    @contact["list"].contact_list[@section.to_i] << ''
    session[:contact_list] = @contact["list"]
    render :update do |page|
      page.replace_html("contactcap", :partial => "rubycms/contact/contact")
    end
  end
  
  def delete_from_contacts
    @page = Page.find(params[:page])
    @section = params[:section]
    @line = params[:line]
    @contact = {"list" => session[:contact_list]}
    @contact["list"].contact_list.delete_at(@section.to_i) if @line.to_i == 0
    @contact["list"].contact_list[@section.to_i].delete_at(@line.to_i) if @line.to_i > 0
    session[:contact_list] = @contact["list"]
    render :update do |page|
      page.replace_html("contactcap", :partial => "rubycms/contact/contact")
    end
  end

  def revert_contacts
    @page = Page.find(params[:page])
    @contact = {}
    if @page.contact_id == nil
      @contact.default = nil
    else
      @contact.default = Contact.find(@page.contact_id) 
    end 
    @contact["list"] = Clist.new(@contact.default)
    session[:contact_list] = Clist.new(@contact.default)
    @contact["hide"] = session[:contact_hide]
    flash[:notice] = 'Contacts reverted.'
    render :update do |page|
      page.replace_html("contactcap", :partial => "rubycms/contact/contact")
    end
  end 
  
  def import_contacts
    @page = Page.find(params[:page].gsub(/^\//, ""))
    @contact = {}
    importpage = Page.find_page(params[:importpath].to_s.sub(/^\//, ""))
    
    if importpage == nil || importpage.contact_id == nil
      flash[:notice] = 'Contacts not imported.'
      @contact["list"] = session[:contact_list]
      @contact["hide"] = session[:contact_hide]
    else
      flash[:notice] = params[:importpath] + ' imported.'
      @contact.default = Contact.find(importpage.contact_id)
      @contact["list"] = Clist.new(@contact.default)
      session[:contact_list] = Clist.new(@contact.default)
      @contact["hide"] = session[:contact_hide]
    end
    
    render :update do |page|
      page.replace_html("contactcap", :partial => "rubycms/contact/contact")
    end
  end 
end
