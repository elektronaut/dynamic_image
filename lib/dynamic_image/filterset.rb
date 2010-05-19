require 'dynamic_image'

module DynamicImage

	@@filtersets = Hash.new
	
	# Singleton methods for the filtersets hash.
	class << @@filtersets
		def names; keys; end
	end
	
	# Accessor for the filtersets hash. Installed filter names are available through the <tt>names</tt> method. Example:
	#   @filter_names = DynamicImage.filtersets.names
	def self.filtersets
		@@filtersets
	end
	
	# Base class for filter sets. Extending this with your own subclasses will automatically enable them for use.
	# You'll need to overwrite <tt>Filterset.process</tt> in order to make your filter useful. Note that it's a class
	# method.
	#
	# === Example
	#
	#   class BlogThumbnailsFilterset < DynamicImage::Filterset
	#     def self.process(image)
	#       image = image.sepiatone     # convert the image to sepia tones
	#     end
	#   end
	#
	# The filter set is now available for use in your application:
	#
	#   <%= dynamic_image_tag( @blog_post.image, :size => "120x100", :filterset => 'blog_thumbnails' ) %>
	#
	# === Applying effects by default
	#
	# If <tt>Image.get_oricessed</tt> is called without filters, it will look for a set named 'default'.
	# This means that you can automatically apply effects on resized images by defining a class called <tt>DefaultFilterset</tt>:
	#
	#   class DefaultFilterset < DynamicImage::Filterset
	#     def self.process(image)
	#       image = image.unsharp_mask  # apply unsharp mask on images by default.
	#     end
	#   end
	#
	# === Chaining filters
	#
	# You can only apply one filterset on an image, but compound filters can easily be created:
	#
	#   class CompoundFilterset < DynamicImage::Filterset
	#     def self.process(image)
	#       image = MyFirstFilterset.process(image)
	#       image = SomeOtherFilterset.process(image)
	#       image = DefaultFilterset.process(image)
	#     end
	#   end
	#
	class Filterset
		include ::Magick

		# Detect inheritance and store the new filterset in the lookup table.
		def self.inherited(sub)
			filter_name = sub.name.gsub!( /Filterset$/, '' ).underscore
			DynamicImage.filtersets[filter_name] = sub
		end

		# Get a Filterset class by name. Accepts a symbol or string, CamelCase and under_scores both work.
		def self.[](filter_name)
			filter_name = filter_name.to_s if filter_name.kind_of? Symbol
			filter_name = filter_name.underscore
			DynamicImage.filtersets[filter_name] || nil
		end

		# Process the image. This is a dummy method, you should overwrite it in your subclass.
		def self.process(image)
			# This is a stub
		end
		
	end
end