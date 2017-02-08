module ActiveRecord # :nodoc:
  module Acts #:nodoc:
    module Descriptable
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_descriptable(style = :serialized)
          include "ActiveRecord::Acts::Descriptable::InstanceMethods::#{style.to_s.classify}".constantize
          extend ActiveRecord::Acts::Descriptable::SingletonMethods
        end
      end

      module SingletonMethods
        def search(descriptors)
          conditions = ''
          for descriptor in descriptors
            conditions += "descriptors LIKE '%"
            conditions += descriptor.name + ': "' + descriptor.value + "\"%' or "
          end
          conditions.gsub!(/ or $/, '')
          logger.info 'Searching for: ' + conditions
          where(conditions)
        end

        def find_descriptors
          logger.info 'Finding all descriptors'
          response = []
          find_each do |object|
            object.descriptors.each do |descriptor|
              response.push descriptor
            end
          end
          response
        end
      end

      module InstanceMethods
        module Active
          def self.included(base)
            base.class_eval do
              has_many :descriptors, ->() { order('sorter') }, dependent: :destroy
            end
          end

          def create_descriptors(params)
            descriptors << params.sort_by { |k, _| k.to_i }.each_with_index.map do |(_field_id, value), index|
              value[:required] = (value[:required] == 'on') ? 1 : 0
              Descriptor.new(value.merge(sorter: index + 1))
            end
          end

          def update_descriptors(params)
            delete_descriptors
            create_descriptors(params)
          end

          def delete_descriptors
            descriptors.clear
          end
        end

        module Serialized
          def self.included(base)
            base.class_eval do
              serialize :descriptors
              serialize :descriptor_fields
            end
          end

          def descriptor_xml(options = {})
            xml = options[:builder] ||= Builder::XmlMarkup.new(indent: options[:indent])
            xml.instruct! unless options[:skip_instruct]

            xml.descriptors {
              descriptors.each do |field|
                xml.descriptor {
                  descriptor.name  field.name.to_s
                  descriptor.value field.value
                }
              end
            }
          end

          def descriptors
            [].tap do |response|
              each_descriptor do |field, value|
                response.push(Descriptor.new(name: field, value: value))
              end
            end
          end

          def each_descriptor
            descriptor_hash = read_descriptor_hash
            read_descriptor_fields.each do |field|
              next if field.blank?
              yield(field, descriptor_hash[field])
            end
          end

          def descriptor_value(key)
            read_descriptor_hash.fetch(key, '')
          end

          # I'm going to unpick this completely soon
          # but need to work out exactly what's used
          def descriptor_value_allow_nil(key)
            read_descriptor_hash[key]
          end

          def add_descriptor(descriptor)
            write_attribute(:descriptors,       read_descriptor_hash.merge(descriptor.name => descriptor.value))
            write_attribute(:descriptor_fields, read_descriptor_fields.push(descriptor.name))
          end

          def read_descriptor_hash
            read_attribute(:descriptors) || {}
          end
          private :read_descriptor_hash

          def read_descriptor_fields
            descriptor_fields || []
          end
          private :read_descriptor_fields
        end
      end
    end
  end
end
