require 'binary_storage'

module BinaryStorage
  module ActiveRecordExtensions

    def self.included(base)
      base.send(:extend, BinaryStorage::ActiveRecordExtensions::ClassMethods)
    end
    
    module ClassMethods
      
      def register_binary(klass, binary_name, binary_column)
        @@binary_columns ||= {}
        @@binary_columns[klass] ||= {}
        @@binary_columns[klass][binary_name] = binary_column
      end
      
      def binary_column(klass, binary_name)
        if @@binary_columns && @@binary_columns[klass] && @@binary_columns[klass][binary_name]
          @@binary_columns[klass][binary_name]
        else
          nil
        end
      end
      
      # Count existing references to a binary
      def binary_reference_count(hash_string)
        references = 0
        if @@binary_columns
          @@binary_columns.each do |klass, binaries|
            binaries.each do |binary_name, binary_column|
              references += klass.count(:all, :conditions => ["`#{binary_column} = ?`", hash_string])
            end
          end
        end
      end
      
      def binary_storage(binary_name, binary_column)
        binary_name   = binary_name.to_s
        binary_column = binary_column.to_s

        register_binary(self, binary_name, binary_column)

        class_eval <<-end_eval
          before_save do |binary_model|
            binary_model.save_binary("#{binary_name}")
          end
          
          after_destroy do |model|
            binary_model.destroy_binary("#{binary_name}")
          end

          def #{binary_name}
            self.get_binary_data("#{binary_name}")
          end

          def #{binary_name}=(binary_data)
            self.set_binary_data("#{binary_name}", binary_data)
          end

          def #{binary_name}?
            self.has_binary_data?("#{binary_name}")
          end
        end_eval

        send(:include, BinaryStorage::ActiveRecordExtensions::InstanceMethods)
      end
    end
    
    module InstanceMethods
      
      def binaries
        @binaries ||= {}
      end

      def binary_column(binary_name)
        if column_name = self.class.binary_column(self.class, binary_name) 
          column_name
        else 
          raise "Binary column #{binary_name} not defined!"
        end
      end
      
      def binary_hash_string(binary_name)
        self.attributes[binary_column(binary_name)]
      end

      def save_binary(binary_name)
        if binaries.has_key?(binary_name)
          if binary = binaries[binary_name]
            binary.save
            self.attributes = self.attributes.merge({binary_column(binary_name).to_sym => binary.hash_string})
          else
            self.attributes = self.attributes.merge({binary_column(binary_name).to_sym => nil})
          end
        end
      end

      def destroy_binary(binary_name)
        if binary = binaries[binary_name]
          if hash_string = binary.hash_string
            references = self.class.binary_reference_count
            if references < 1
              binary.delete!
            end
          end
        end
      end
      
      def get_binary_data(binary_name)
        # Set directly?
        if binary = binaries[binary_name]
          binary.data

        # Try loading
        elsif hash_string = binary_hash_string(binary_name)
          if binary = BinaryStorage::Blob.find(hash_string)
            binaries[binary_name] = binary # Cache it
            binary.data
          else
            nil
          end
        end
      end
      
      def set_binary_data(binary_name, binary_data)
        binary = (binary_data) ? BinaryStorage::Blob.new(binary_data) : nil
        binaries[binary_name] = binary
      end
      
      def has_binary_data?(binary_name)
        if binaries[binary_name]
          true
        else
          hash_string = binary_hash_string(binary_name)
          (hash_string && BinaryStorage::Blob.exists?(hash_string)) ? true : false
        end
      end
    end

  end
end

ActiveRecord::Base.send(:include, BinaryStorage::ActiveRecordExtensions)
