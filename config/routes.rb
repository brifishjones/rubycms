ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  map.root :controller => "site", :action => "show"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.

  map.connect 'edit/*url', :controller => 'site', :action => 'edit'
  map.connect 'staging/*url', :controller => 'site', :action => 'show'
  map.connect 'pageid/*url', :controller => 'site', :action => 'show'   # used to show previous versions of a page

  # route all rubycms modules present in app/controllers/rubycms
  Dir.glob("app/controllers/rubycms/**/*.rb").each do |i|
    modname = i.sub(/^app\/controllers\/rubycms\//, "").sub(/_controller\.rb$/, "")
    map.connect 'rubycms_' + modname + '/:action/:id', :controller => 'rubycms/' + modname  # note: rubycms_modname.  Used to route ajax calls
    map.connect 'rubycms/' + modname + '/*url', :controller => 'rubycms/' + modname, :action => 'show'
  end

  # work-around for /login proxy
  map.connect 'rubycms_login/:action/:id', :controller => 'login'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect '*url', :controller => 'site', :action => 'show'
end
