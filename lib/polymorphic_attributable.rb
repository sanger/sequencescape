module PolymorphicAttributable

  def self.included(base)
    base.class_eval do
      def self.set_polymorphic_attributes(name, options = {})
        camel_name = name.to_s.camelize
        self.class_eval <<EOR

        def #{name}
          case
          when self.material.nil?
            nil
          when self.material.is_a?(#{camel_name})
            self.material
        else
            nil
          end
        end

        def #{name}=(name_instance)
          if name_instance
            raise ArgumentError, "Can't assing a \#{name_instance.class} to a #{camel_name}" unless name_instance.is_a?(#{camel_name})
        end
          self.material = name_instance
        end


        def #{name}_id
          material_id if self.material_type == "#{camel_name}"
        end

        def #{name}_id= (name_id)
          self.material_id = name_id
          self.material_type = #{camel_name}
          name_id
        end
EOR

      end
    end
  end
end
