module DynamicImage
	module MapperExtensions
		def dynamic_image
			@set.add_route('dynamic_image/:id/:original/:size/:filterset/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/, :original => /original/ }})
			@set.add_route('dynamic_image/:id/:original/:size/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/, :original => /original/ }})
			@set.add_route('dynamic_image/:id/:original/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :original => /original/ }})

			@set.add_route('dynamic_image/:id/:size/:filterset/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }})
			@set.add_route('dynamic_image/:id/:size/*filename', {:controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }})
			@set.add_route('dynamic_image/:id/*filename', {:controller => 'images', :action => 'render_dynamic_image'})
		end
 	end
end