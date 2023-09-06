module CarrierWave
  module Uploader
    module Versions
      module ClassMethods
        def build_version(name, options)
          if versions.has_key?(name)
            uploader = Class.new(versions[name])
            const_set("Uploader#{name}".tr('-', '_'), uploader)
            uploader.processors = []
            uploader.version_options = uploader.version_options.merge(options)
          else
            uploader = Class.new(self)
            const_set("Uploader#{name}".tr('-', '_'), uploader)
            uploader.version_names += [name]
            uploader.versions = {}
            uploader.processors = []
            uploader.version_options = options

            uploader.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              # Define the enable_processing method for versions so they get the
              # value from the parent class unless explicitly overwritten
              def self.enable_processing(value=nil)
                self.enable_processing = value if value
                if defined?(@enable_processing) && !@enable_processing.nil?
                  @enable_processing
                else
                  superclass.enable_processing
                end
              end

              # Regardless of what is set in the parent uploader, do not enforce the
              # move_to_cache config option on versions because it moves the original
              # file to the version's target file.
              #
              # If you want to enforce this setting on versions, override this method
              # in each version:
              #
              # version :thumb do
              #   def move_to_cache
              #     true
              #   end
              # end
              #
              def move_to_cache
                false
              end
            RUBY

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                versions[:#{name}]
              end
            RUBY
          end

          # Add the current version hash to class attribute :versions
          self.versions = versions.merge(name => uploader)
        end
      end # ClassMethods
    end
  end
end
