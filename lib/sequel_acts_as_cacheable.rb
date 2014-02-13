module Sequel
  module Plugins
    module ActsAsCacheable
      def self.configure(model, opts={})
        model.instance_eval do
          @acts_as_cacheable_cache = opts[:cache]
          @acts_as_cacheable_time_to_live = opts[:time_to_live] || 3600
          @acts_as_cacheable_logger = opts[:logger]
        end
      end

      module ClassMethods
        attr_accessor :acts_as_cacheable_cache
        attr_accessor :acts_as_cacheable_time_to_live
        attr_accessor :acts_as_cacheable_logger

        # Copy the necessary class instance variables to the subclass.
        def inherited(subclass)
          super
          subclass.acts_as_cacheable_cache = acts_as_cacheable_cache
          subclass.acts_as_cacheable_time_to_live = acts_as_cacheable_time_to_live
          subclass.acts_as_cacheable_logger = acts_as_cacheable_logger
        end

        def model_cache_key model_id
          base_model_klass = self
          base_model_klass = base_model_klass.superclass while Sequel::Model != base_model_klass.superclass
          "#{base_model_klass.name}~#{model_id}"
        end

        def [](*args)
          is_primary_key_lookup =
              if 1 == args.size
                if Fixnum == args.first.class
                  true
                else
                  if String == args.first.class
                    begin
                      Integer(args.first)
                      true
                    rescue
                      false
                    end
                  else
                    false
                  end
                end
              else
                false
              end

          if is_primary_key_lookup
            key = model_cache_key args.first
            begin
              cache_value = @acts_as_cacheable_cache.get key
            rescue Exception => e
              if acts_as_cacheable_logger
                acts_as_cacheable_logger.error "CACHE.get failed in primary key lookup with args #{args.inspect} and model #{self.class.name} so using mysql lookup instead, exception was #{e.inspect}"
              end
              cache_value = super *args
            end

            if !cache_value
              cache_value = super *args
              cache_value.cache! if cache_value
            end

            if cache_value.kind_of? self
              cache_value
            else
              nil
            end
          else
            super *args
          end
        end
      end

      module InstanceMethods
        def cache!
          unless new?
            marshallable!
            if respond_to? :before_cache
              before_cache
            end
            acts_as_cacheable_cache.set model_cache_key, self, acts_as_cacheable_time_to_live
          end
        end

        def uncache!
          acts_as_cacheable_cache.delete self.class.model_cache_key id
        end

        alias_method :invalidate_cache!, :uncache!

        def cached?
          acts_as_cacheable_cache.get(model_cache_key).present?
        end

        def save *columns
          result = super *columns
          invalidate_cache! if result && !new?
          result
        end

        def delete
          begin
            result = super
          rescue Sequel::NoExistingObject
            if acts_as_cacheable_logger
              acts_as_cacheable_logger.error "attempted to delete a record that doesn't exist"
            end
          end
          invalidate_cache!
          result
        end

        def destroy opts = {}
          result = super opts
          invalidate_cache! unless false == result
          result
        end

        private
        def model_cache_key
          model.model_cache_key id
        end

        def acts_as_cacheable_cache
          model.acts_as_cacheable_cache
        end

        def acts_as_cacheable_time_to_live
          model.acts_as_cacheable_time_to_live
        end
      end
    end
  end
end





