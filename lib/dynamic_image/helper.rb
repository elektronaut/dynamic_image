require 'dynamic_image'

module DynamicImage
	module Helper

		# Returns an hash consisting of the URL to the dynamic image and parsed options. This is mostly for internal use by 
		# dynamic_image_tag and dynamic_image_url.
		def dynamic_image_options(image, options = {})
			options.symbolize_keys!

			options     = {:crop => false}.merge(options)
			url_options = {:controller => "/images", :action => :render_dynamic_image, :id => image}
		
			if options[:original]
				url_options[:original] = 'original'
				options.delete(:original)
			end

			# Image sizing
			if options[:size]
				new_size   = Vector2d.new(options[:size])
				image_size = Vector2d.new(image.size)

	            unless options[:upscale]
				    new_size.x = image_size.x if new_size.x > 0 && new_size.x > image_size.x
				    new_size.y = image_size.y if new_size.y > 0 && new_size.y > image_size.y
			    end

				unless options[:crop]
					new_size = image_size.constrain_both(new_size)
				end

				options[:size] = new_size.round.to_s
				url_options[:size] = options[:size]
			end
			options.delete :crop

			if options[:no_size_attr]
				options.delete :no_size_attr
				options.delete :size
			end

			# Filterset
			if options[:filterset]
				url_options[:filterset] = options[:filterset]
				options.delete :filterset
			end

			# Filename
			if options[:filename]
				filename = options[:filename]
				unless filename =~ /\.[\w]{1,4}$/
					filename += "." + image.filename.split(".").last
				end
				url_options[:filename] = filename
			else
				url_options[:filename] = image.filename
			end

			# Alt attribute
			options[:alt] ||= image.name if image.name?
			options[:alt] ||= image.filename.split('.').first.capitalize
		
			if options.has_key?(:only_path)
				url_options[:only_path] = options[:only_path]
				options[:only_path] = nil
			end
			if options.has_key?(:host)
				url_options[:host] = options[:host]
				options[:host] = nil
			end
		
			{:url => url_for(url_options), :options => options}
		end
	
		# Returns an image tag for the provided image model, works similar to the rails <tt>image_tag</tt> helper. 
		# The <tt>alt</tt> tag is set to the image title unless explicitly provided.
		#
		# The following options are supported (the rest will be forwarded to <tt>image_tag</tt>):
		#
		#   :size         - Resize the image to fit these proportions. Size is given as a string with the format
		#                   '100x100'. Either dimension can be omitted, for example: '100x'
		#   :crop         - Boolean, default: false. Crop the image to the size given.
		#   :no_size_attr - Boolean, default: false. Do not include width and height attributes in the image tag.
		#   :filterset    - Apply the given filterset to the image
		#
		# == Examples
		#
		# Tag for original image, without rescaling:
		#   <%= dynamic_image_tag(@image) %>
		#
		# Tag for image, rescaled to fit within 100x100 (size will be 100x100 or smaller):
		#   <%= dynamic_image_tag(@image, :size => "100x100") %>
		#
		# Tag for image, cropped and rescaled to 100x100 (size will be 100x100 in all cases):
		#   <%= dynamic_image_tag(@image, :size => "100x100", :crop => true) %>
		#
		# Tag for image with a filter set applied:
		#   <%= dynamic_image_tag(@image, :size => "100x100", :filterset => @filterset) %>
		#
		# Tag for image with a named filter set applied:
		#   <%= dynamic_image_tag(@image, :size => "100x100", :filterset => "thumbnails") %>
		#
		# Tag for image without the width/height attributes, and with a custom alt attribute
		#   <%= dynamic_image_tag(@image, :size => "100x100", :no_size_attr => true, :alt => "Thumbnail for post" %>
	
		def dynamic_image_tag(image, options = {})
			parsed_options = dynamic_image_options(image, options)
			image_tag(parsed_options[:url], parsed_options[:options] ).gsub(/\?[\d]+/,'')
		end
	
		# Returns an url corresponding to the provided image model.
		# Special options are documented in ApplicationHelper.dynamic_image_tag, only <tt>:size</tt>, <tt>:filterset</tt> and <tt>:crop</tt> apply.
		def dynamic_image_url(image, options = {})
			parsed_options = dynamic_image_options(image, options)
			parsed_options[:url]
		end
	end
end
