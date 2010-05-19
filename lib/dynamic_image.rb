
# Gem dependencies
require 'rmagick'
require 'vector2d'
require 'rails'
require 'action_controller'
require 'active_support'
require 'active_record'

if Rails::VERSION::MAJOR == 3
	# Load the engine
	require 'dynamic_image/engine' if defined?(Rails)
end

require 'dynamic_image/filterset'
require 'dynamic_image/helper'
require 'dynamic_image/active_record_extensions'
require 'dynamic_image/mapper_extensions'

require 'dynamic_image/images_controller'
require 'dynamic_image/image_model'
#require 'dynamic_image/binary_model'

module DynamicImage
	@@dirty_memory = false
	@@page_caching = true
	
	class << self
		
		def dirty_memory=(flag)
			@@dirty_memory = flag
		end
		
		def dirty_memory
			@@dirty_memory
		end
		
		def page_caching=(flag)
			@@page_caching = flag
		end
		
		def page_caching
			@@page_caching
		end

		# RMagick stores image data internally, Ruby doesn't see the used memory.
		# This method performs garbage collection if @@dirty_memory has been flagged.
		# More details here: http://rubyforge.org/forum/message.php?msg_id=1995
		def clean_dirty_memory(options={})
			options.symbolize_keys!
			if @@dirty_memory || options[:force]
				gc_disabled = GC.enable
				GC.start
				GC.disable if gc_disabled
				@@dirty_memory = false
				true
			else
				false
			end
		end
	end
end

#ActionController::Routing::RouteSet::Mapper.send :include, DynamicImage::MapperExtensions
ActiveRecord::Base.send(:include, DynamicImage::ActiveRecordExtensions)
ActionView::Base.send(:include, DynamicImage::Helper)
