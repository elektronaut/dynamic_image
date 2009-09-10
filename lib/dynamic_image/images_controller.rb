module DynamicImage
	class ImagesController < ApplicationController
	
		session :off

		def render_missing_image
			if self.respond_to?( :render_error )
				render_error 404
			else
				render :status => 404, :text => "404: Image not found"
			end
		end
		protected :render_missing_image

		# Return the requested image. Rescale, filter and cache it where appropriate.
		def render_dynamic_image
			minTime = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil

			render_missing_image and return unless Image.exists?(params[:id])

			image = Image.find(params[:id])

			if minTime && image.created_at? && image.created_at <= minTime
				render :text => '304 Not Modified', :status => 304
				return
			end
		
			unless image.data
				logger.warn "Image #{image.id} exists, but has no data"
				render_missing_image and return
			end

			if size = params[:size]
			    if size =~ /^x[\d]+$/ || size =~ /^[\d]+x$/
					if params[:original]
						image.cropped = false
					end
			        size = Vector2d.new(size)
				    image_size = Vector2d.new(image.size)
				    size = image_size.constrain_both(size).round.to_s
				end
	    		imagedata = image.get_processed(size, params[:filterset])
		    else
	    		imagedata = image
	        end

			DynamicImage.dirty_memory = true # Flag memory for GC

			if image
				response.headers['Cache-Control'] = nil
				response.headers['Last-Modified'] = imagedata.created_at.httpdate if imagedata.created_at?
				send_data( 
					imagedata.data, 
					:filename    => image.filename, 
					:type        => image.content_type, 
					:disposition => 'inline'
				)
			end
		
		end
	
		# Enforce caching of dynamic images, even if caching is turned off
		def cache_dynamic_image
			cache_setting = ActionController::Base.perform_caching
			ActionController::Base.perform_caching = true
			cache_page
			ActionController::Base.perform_caching = cache_setting
		end
		after_filter :cache_dynamic_image
	
		# Perform garbage collection if necessary
		def run_garbage_collection_for_dynamic_image_controller
			DynamicImage.clean_dirty_memory
		end
		protected    :run_garbage_collection_for_dynamic_image_controller
		after_filter :run_garbage_collection_for_dynamic_image_controller

	end
end