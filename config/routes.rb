# Rails 3 routes
Rails.application.routes.draw do
  get "dynamic_images/:id/:original(/:size(/:filterset))/*filename" => "images#render_dynamic_image", :size => /\d*x\d*/, :original => /original/
  get "dynamic_images/:id(/:size(/:filterset))/*filename" => "images#render_dynamic_image", :size => /\d*x\d*/
  # Legacy
  get "dynamic_image/:id/:original(/:size(/:filterset))/*filename" => "images#render_dynamic_image", :size => /\d*x\d*/, :original => /original/
  get "dynamic_image/:id(/:size(/:filterset))/*filename" => "images#render_dynamic_image", :size => /\d*x\d*/
end

# Rails 2 routes
#@set.add_route('dynamic_image/:id/:original/:size/:filterset/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/, :original => /original/ }})
#@set.add_route('dynamic_image/:id/:original/:size/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/, :original => /original/ }})
#@set.add_route('dynamic_image/:id/:original/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :original => /original/ }})
#@set.add_route('dynamic_image/:id/:size/:filterset/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }})
#@set.add_route('dynamic_image/:id/:size/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }})
#@set.add_route('dynamic_image/:id/*filename', {:controller => 'images', :action => 'render_dynamic_image'})
