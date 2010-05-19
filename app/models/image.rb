class Image < ActiveRecord::Base
	unloadable

	binary_storage :data, :sha1_hash

	validates_format_of :content_type, 
	                    :with => /^image/,
		                :message => "you can only upload pictures"

	attr_accessor :filterset, :data_checked, :skip_maxsize

	# Sanitize the filename and set the name to the filename if omitted
	validate do |image|
		image.name     = File.basename(image.filename, ".*") if !image.name || image.name.strip == ""
		image.filename = image.friendly_file_name(image.filename)
		if image.cropped?
			image.errors.add(:crop_start, "must be a vector") unless image.crop_start =~ /^[\d]+x[\d]+$/
			image.errors.add(:crop_size,  "must be a vector") unless image.crop_size  =~ /^[\d]+x[\d]+$/
		else
			image.crop_size  = image.original_size
			image.crop_start = "0x0"
		end
	end

	# Set the image data
	#alias_method :binary_data=, :data=
	#def data=(blob)
	#	binary_data = blob
	#	self.check_image_data
	#end

	# Create the binary from an image file.
	def imagefile=(image_file)
		self.filename     = image_file.original_filename rescue File.basename( image_file.path )
		self.content_type = image_file.content_type.chomp rescue "image/"+image_file.path.split(/\./).last.downcase.gsub(/jpg/,"jpeg") # ugly hack
		set_image_data(image_file.read)
	end

	# Return the image hotspot
	def hotspot
		(self.hotspot?) ? self.hotspot : (Vector2d.new(self.size) * 0.5).round.to_s
	end

	# Check the image data
	def set_image_data(data)
		self.data = data
		if self.data?
			image     = Magick::ImageList.new.from_blob(self.data)
			size      = Vector2d.new(image.columns, image.rows)
			if DynamicImage.crash_size
				crashsize = Vector2d.new(DynamicImage.crash_size)
				if (size.x > crashsize.x || size.y > crashsize.y)
					raise "Image too large!"
				end
			end
			if DynamicImage.max_size && !self.skip_maxsize
				maxsize = Vector2d.new(DynamicImage.max_size)
				if (size.x > maxsize.x || size.y > maxsize.y)
					size = size.constrain_both(maxsize).round
					image.resize!(size.x, size.y)
					self.data = image.to_blob
				end
			end
			# Convert image to a proper format
			unless image.format =~ /(JPEG|PNG|GIF)/
				self.data = image.to_blob{self.format = 'JPEG'; self.quality = 90}
				self.filename += ".jpg"
				self.content_type = "image/jpeg"
			end
			self.original_size = size.round.to_s
		end
	end

	# Returns the image width
	def original_width
		Vector2d.new(self.original_size).x.to_i
	end

	# Returns the image height
	def original_height
		Vector2d.new(self.original_size).y.to_i
	end

	def crop_start_x
		Vector2d.new(self.crop_start).x.to_i
	end
	def crop_start_y
		Vector2d.new(self.crop_start).y.to_i
	end
	def crop_width
		Vector2d.new(self.crop_size).x.to_i
	end
	def crop_height
		Vector2d.new(self.crop_size).y.to_i
	end

	# Returns original or cropped size
	def size
		(self.cropped?) ? self.crop_size : self.original_size
	end

	def size=(new_size)
		self.original_size = new_size
	end

	# Convert file name to a more file system friendly one.
	# TODO: international chars
	def friendly_file_name( file_name )
		[["æ","ae"], ["ø","oe"], ["å","aa"]].each do |int|
			file_name = file_name.gsub(int[0], int[1])
		end
		File.basename(file_name).gsub(/[^\w\d\.-]/, "_")
	end

	# Get the base part of a filename
	def base_part_of(file_name)
		name = File.basename(file_name)
		name.gsub(/[ˆ\w._-]/, '')
	end

	# Rescale and crop the image, and return it as a blob.
	def rescaled_and_cropped_data(*args)
		DynamicImage.dirty_memory = true                                                       # Flag to perform GC
		data = Magick::ImageList.new.from_blob(self.data)

		if self.cropped?
			cropped_start = Vector2d.new(self.crop_start).round
			cropped_size  = Vector2d.new(self.crop_size).round
			data = data.crop(cropped_start.x, cropped_start.y, cropped_size.x, cropped_size.y, true)
		end

		size         = Vector2d.new(self.size)
		rescale_size = size.dup.constrain_one(args).round                                      # Rescale dimensions
		crop_to_size = Vector2d.new(args).round                                                # Crop size
		new_hotspot  = Vector2d.new(hotspot) * (rescale_size / size)                           # Recalculated hotspot
		rect = [(new_hotspot-(crop_to_size/2)).round, (new_hotspot+(crop_to_size/2)).round]    # Array containing crop coords

		# Adjustments
		x = rect[0].x; rect.each{|r| r.x += (x.abs)}            if x < 0
		y = rect[0].y; rect.each{|r| r.y += (y.abs)}            if y < 0
		x = rect[1].x; rect.each{|r| r.x -= (x-rescale_size.x)} if x > rescale_size.x
		y = rect[1].y; rect.each{|r| r.y -= (y-rescale_size.y)} if y > rescale_size.y

		rect[0].round!
		rect[1].round!

		data = data.resize(rescale_size.x, rescale_size.y)
		data = data.crop(rect[0].x, rect[0].y, crop_to_size.x, crop_to_size.y)
		data.to_blob{self.quality = 90}
	end

	def constrain_size(*max_size)
		Vector2d.new(self.size).constrain_both(max_size.flatten).round.to_s
	end

	# Get a duplicate image with resizing and filters applied.
	def get_processed(size, filterset=nil)
		size                      = Vector2d.new(size).round.to_s
		processed_image           = Image.new
		processed_image.filterset = filterset || 'default'
		processed_image.data      = self.rescaled_and_cropped_data(size)
		processed_image.size      = size
		processed_image.apply_filters
		processed_image
	end

	# Apply filters to image data
	def apply_filters
		filterset_name = self.filterset || 'default'
		filterset = DynamicImage::Filterset[filterset_name]
		if filterset
			DynamicImage.dirty_memory = true # Flag for GC
			data = Magick::ImageList.new.from_blob(self.data)
			data = filterset.process(data)
			self.data = data.to_blob
		end
	end

	# Decorates to_json with additional attributes
	def to_json
		attributes.merge({
			:original_width  => self.original_width, 
			:original_height => self.original_height,
			:crop_width      => self.crop_width,
			:crop_height     => self.crop_height,
			:crop_start_x    => self.crop_start_x,
			:crop_start_y    => self.crop_start_y
		}).to_json
	end
end