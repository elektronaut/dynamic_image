require 'dynamic_image'

module DynamicImage
	module ActiveRecordExtensions

		def self.included(base)
			base.send :extend, ClassMethods
		end

		module ClassMethods
			# By using <tt>belongs_to_image</tt> over <tt>belongs_to</tt>, you gain the ability to
			# set the image directly from an uploaded file. This works exactly like <tt>belongs_to</tt>,
			# except the class name will default to 'Image' - not the name of the association.
			# 
			# Example:
			#
			#   # Model code
			#   class Person < ActiveRecord::Base
			#     belongs_to_image :mugshot
			#   end
			#
			#   # View code
			#   <% form_for 'person', @person, :html => {:multipart => true} do |f| %>
			#     <%= f.file_field :mugshot %>
			#   <% end %>
			#
			def belongs_to_image(association_id, options={})
				options[:class_name] ||= 'Image'
				options[:foreign_key] ||= options[:class_name].downcase+'_id'
				belongs_to association_id, options

				# Overwrite the setter method
				class_eval <<-end_eval
					alias_method :associated_#{association_id}=, :#{association_id}=
					def #{association_id}=(img_obj)
						# Convert a Tempfile to a proper Image
						unless img_obj.kind_of?(ActiveRecord::Base)
							DynamicImage.dirty_memory = true # Flag for GC
							img_obj = Image.create(:imagefile => img_obj)
						end
						# Quietly skip blank strings
						unless img_obj.kind_of?(String) && img_obj.blank?
							self.associated_#{association_id} = img_obj
						end
					end
				end_eval

				send :include, DynamicImage::ActiveRecordExtensions::InstanceMethods
			end 
		end

		module InstanceMethods
		end
	end
end

ActiveRecord::Base.send(:include, DynamicImage::ActiveRecordExtensions)
