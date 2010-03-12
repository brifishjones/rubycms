class Rubycms::LayoutController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @layout = {"name" => session[:layout]}
  end  
  
  def change_layout
    @page = Page.find(params[:page]) 
    @layout = {"name" => params[:name]}
    session[:layout] = @layout["name"]
    render :partial => 'rubycms/layout/layout'
  end

  def clear_layout
    @page = Page.find(params[:page])
    @layout = {"name" => nil}
    session[:layout] = nil
    render :partial => 'rubycms/layout/layout'
  end

end
