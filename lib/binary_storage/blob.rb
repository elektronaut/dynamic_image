module BinaryStorage
	class Blob
		
		class << self
			def find(hash_string)
				blob = self.new(:hash_string => hash_string)
				return nil unless blob.exists?
				blob.load
				blob
			end

			def exists?(hash_string)
				self.new(:hash_string => hash_string).exists?
			end

			def create(data)
				blob = self.new(data)
				blob.save
				blob
			end
			
			def storage_dir(hash_string=nil)
				root = BinaryStorage.storage_dir
				(hash_string) ? File.join(root, hash_string.match(/^(..)/)[1]) : root
			end
			
			def storage_path(hash_string)
				File.join(storage_dir(hash_string), hash_string.gsub(/^(..)/, ''))
			end
		end
		
		def initialize(*args)
			args = *args
			options = {
				:hash_string => nil,
				:data        => nil
			}
			if args.kind_of?(Hash)
				options.merge!(args)
			else
				options[:data] = args
			end
			@hash_string = options[:hash_string]
			data         = options[:data]
		end
		
		def data
			@data
		end
		
		def data=(new_data)
			@hash_string = nil
			@data        = new_data
		end
		
		def hash_string
			unless @hash_string
				if @data
					@hash_string = BinaryStorage.hexdigest(data)
				else
					raise "Binary has no data!" 
				end
			end
			@hash_string
		end
		
		def storage_dir
			BinaryStorage::Blob.storage_dir(hash_string)
		end

		def storage_path
			BinaryStorage::Blob.storage_path(hash_string)
		end
		
		def exists?
			File.exists?(storage_path)
		end
		
		def empty?
			(hash_string && !exists?) || !data || data.empty?
		end
		
		def load
			raise "File not found" unless exists?
			@data = File.open(storage_path, "rb") {|io| io.read }
		end
		
		def delete
			if exists?
				FileUtils.rm(storage_path)
			end
		end

		def save
			unless exists?
				FileUtils.mkdir_p(storage_dir)
				file = File.new(tmpfile.path, 'wb')
				file.write(@data)
				file.close
			end
			return true
		end
		
	end
end