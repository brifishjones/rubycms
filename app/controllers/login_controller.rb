class LoginController < ApplicationController

  layout RCMS_LAYOUT_DEFAULT

  def index
    if session[:username] != nil
      flash[:notice] = session[:username] + " logged out"
    end
    session[:username] = nil
    if request.post?
      # change the next line to "if true" when developing off-site
      if Localuser.authenticate(params[:name], params[:password]) || User.authenticate(params[:name], params[:password])
        flash[:notice] = "Authorization Successful"
        session[:username] = (params[:name])
        # add to active users if not already present
        u = User.new
        u.name = session[:username]
        u.save if u.unique
        if session[:previous_uri] == nil
          if session[:original_uri] != nil
            uri = session[:original_uri]
          else  # if login is the first place a user goes, redirect to the default page
            uri = "/"
            session[:original_uri] = uri
          end
        else
          uri = session[:previous_uri]
          session[:previous_uri] = nil
        end      
        redirect_to(uri || {:action => "index"})
      else
        flash[:notice] = "Invalid user/password combination"
      end
    end
  end

  def logout
    flash[:notice] = session[:username] + " logged out"
    session[:username] = nil
    redirect_to(session[:original_uri] || {:action => "index"})
  end
  
end
