class DynamicImageGenerator < Rails::Generator::NamedBase
	def manifest
		record do |m|
			m.file 'controllers/images_controller.rb', 'app/controllers/images_controller.rb'
			m.file 'models/image.rb', 'app/models/image.rb'
			m.file 'models/binary.rb', 'app/models/binary.rb'
			m.file 'migrations/20090909231629_create_binaries.rb', 'db/migrate/20090909231629_create_binaries.rb'
			m.file 'migrations/20090909231630_create_images.rb', 'db/migrate/20090909231630_create_images.rb'
			#m.migration_template 'migrations/create_images.rb', 'db/migrate', :migration_file_name => 'create_images'
			#m.migration_template 'migrations/create_binaries.rb', 'db/migrate', :migration_file_name => 'create_binaries'
		end
	end
end