# Rails 2: class DynamicImageGenerator < Rails::Generator::NamedBase

require 'rails/generators'
require 'rails/generators/migration'

class DynamicImageGenerator < Rails::Generators::Base
	
	include Rails::Generators::Migration

	class << self
		def source_root
			@source_root ||= File.join(File.dirname(__FILE__), 'templates')
		end

		def next_migration_number(dirname)
			if ActiveRecord::Base.timestamped_migrations
				Time.now.utc.strftime("%Y%m%d%H%M%S")
			else
				"%.3d" % (current_migration_number(dirname) + 1)
			end
		end

	end

	def migrations
		migration_template 'migrations/create_images.rb', 'db/migrate/create_images.rb'
	end

	# def manifest
	# 	record do |m|
	# 		#m.file 'controllers/images_controller.rb', 'app/controllers/images_controller.rb'
	# 		#m.file 'models/image.rb', 'app/models/image.rb'
	# 		#m.file 'models/binary.rb', 'app/models/binary.rb'
	# 		m.file 'migrations/20090909231629_create_binaries.rb', 'db/migrate/20090909231629_create_binaries.rb'
	# 		m.file 'migrations/20090909231630_create_images.rb', 'db/migrate/20090909231630_create_images.rb'
	# 	end
	# end
end