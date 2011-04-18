module ActiveRecord # :nodoc:
  module Acts #:nodoc:
    module Descriptable
      
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_descriptable(*options)

          if options.to_s == 'active'
            module_eval <<-"end_eval"
              has_many :descriptors
            end_eval
            
            include ActiveRecord::Acts::Descriptable::ActiveInstanceMethods
          else
            module_eval <<-"end_eval"
              serialize :descriptors
              serialize :descriptor_fields
            end_eval
            
            include ActiveRecord::Acts::Descriptable::InstanceMethods
          end
          
          
          extend ActiveRecord::Acts::Descriptable::SingletonMethods
        end
      end
      
      module SingletonMethods
        
        def search(descriptors)
          conditions = ""
          for descriptor in descriptors
            conditions += "descriptors LIKE '%"
            conditions += descriptor.name + ": \"" + descriptor.value + "\"%' or "
          end
          conditions.gsub!(/ or $/, "")
          logger.info "Searching for: " + conditions
          self.find(:all, :conditions => conditions)
        end
        
        def find_descriptors
          logger.info "Finding all descriptors"
          response = []
          self.find(:all).each do |object|
            object.descriptors.each do |descriptor|
              response.push descriptor
            end
          end
          response
        end
        
      end
      
      module ActiveInstanceMethods
        
        def create_descriptors(params)
          count = 0    
          params.keys.sort_by{|key| key.to_i}.each do |field_id|
            count = count + 1
            descriptor = Descriptor.new(params[field_id])
            descriptor.sorter = count
            if params[field_id][:required] == "on"
              descriptor.required = 1
            else
              descriptor.required = 0
            end
            descriptors << descriptor            
          end
        end

        def update_descriptors(params)   
          delete_descriptors
          create_descriptors(params)       
        end
        
        def delete_descriptors
          id = self.descriptors.first
          self.descriptors.each do |d|
            d.destroy
          end
          self.descriptors = []
        end
              
        def descriptors
          self.descriptors.find(self.id, :order => 'sorter')
        end
          
      end
      
      module InstanceMethods
        
        def descriptor_xml(options = {})
          xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
          xml.instruct! unless options[:skip_instruct]

          xml.descriptors do |descriptors|
            if !self.descriptors.nil?
                self.descriptors.each do |field|
                  descriptors.descriptor do |descriptor|
                    descriptor.name field.name.to_s
                    descriptor.value field.value
                  end
                end
            end
          end  
        end
        
        def descriptors
          initialize_fields
          descriptor_hash = read_attribute(:descriptors)
          response = Array.new
          read_attribute(:descriptor_fields).each do |field|
            if !field.nil? and field != ""
              d = Descriptor.new(:name => field, :value => descriptor_hash[field])
              response.push d
            end
          end
          response
        end

        def descriptor_value(key)
          if read_attribute(:descriptors).nil?
            ""
          else
            read_attribute(:descriptors)[key]
          end
        end
                
        def add_descriptor(descriptor)
          initialize_fields
          descriptors = read_attribute(:descriptors)
          write_attribute(:descriptors, descriptors.merge({ descriptor.name => descriptor.value }) )
          write_attribute(:descriptor_fields, read_attribute(:descriptor_fields).push(descriptor.name))
        end
        
        private
        
        def initialize_fields
          if read_attribute(:descriptors).nil?
            write_attribute(:descriptors, {})
          end
          if read_attribute(:descriptor_fields).nil?
            write_attribute(:descriptor_fields, [])
          end          
        end
                
      end
      
    end
  end
end