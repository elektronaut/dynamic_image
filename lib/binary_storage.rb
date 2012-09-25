require 'tempfile'
require 'digest/sha1'

require 'rails'
require 'active_record'

require File.join(File.dirname(__FILE__), 'binary_storage/active_record_extensions')
require File.join(File.dirname(__FILE__), 'binary_storage/blob')

module BinaryStorage
  class << self
    def storage_dir
      @@storage_dir ||= Rails.root.join('db/binary_storage', Rails.env)
    end
    
    def storage_dir=(new_storage_dir)
      @@storage_dir = new_storage_dir
    end
    
    def hexdigest_file(path)
      Digest::SHA1.file(path).hexdigest
    end

    def hexdigest(string)
      Digest::SHA1.hexdigest(string)
    end
  end
end
