class Rubycms::FormController < ApplicationController

  def show
    params[:url] = Array.new if params[:url] == nil
    @page = Page.find_page(params[:url].join("/"))
    @form = {"name" => session[:form]}
  end  
  
  def change_form
    @page = Page.find(params[:page])  
    if (params[:name] == '----- (no form) -----')
      @form = {"name" => nil}
    else
      @form = {"name" => params[:name]}
    end
    
    session[:form] = @form["name"]
    render :partial => 'form'
  end

  def clear_form
    @page = Page.find(params[:page])
    @form = {"name" => nil}
    session[:form] = nil
    render :partial => 'form'
  end

end
