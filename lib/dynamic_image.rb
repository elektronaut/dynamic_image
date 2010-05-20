require 'tempfile'
require 'digest/sha1'
require 'open-uri'

# Gem dependencies
require 'RMagick'
require 'vector2d'
require 'rails'
require 'action_controller'
require 'active_support'
require 'active_record'

require 'binary_storage'

if Rails::VERSION::MAJOR == 3
	# Load the engine
	require 'dynamic_image/engine' if defined?(Rails)
end

require 'dynamic_image/active_record_extensions'
require 'dynamic_image/filterset'
require 'dynamic_image/helper'

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
		
		def max_size
			@@max_size ||= "2000x2000"
		end
		
		def max_size=(new_max_size)
			@@max_size = new_max_size
		end

		def crash_size
			@@crash_size ||= "10000x10000"
		end
		
		def crash_size=(new_crash_size)
			@@crash_size = new_crash_size
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