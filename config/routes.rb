# Rails 3 routes
Rails.application.routes.draw do |map|
	match "dynamic_image/:id/:original(/:size(/:filterset))/*filename" => "images#render_dynamic_image", :constraints => {:size => /[\d]*x[\d]*/, :original => /original/}
	match "dynamic_image/:id(/:size(/:filterset))/*filename"           => "images#render_dynamic_image", :constraints => {:size => /[\d]*x[\d]*/}
end

# Rails 2 routes
#@set.add_route('dynamic_image/:id/:original/:size/:filterset/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/, :original => /original/ }})
#@set.add_route('dynamic_image/:id/:original/:size/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/, :original => /original/ }})
#@set.add_route('dynamic_image/:id/:original/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :original => /original/ }})
#@set.add_route('dynamic_image/:id/:size/:filterset/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }})
#@set.add_route('dynamic_image/:id/:size/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }})
#@set.add_route('dynamic_image/:id/*filename', {:controller => 'images', :action => 'render_dynamic_image'})
