module Sanger
  module Testing
    module Model
      module Macros
        def should_default_everything_but(properties_type, *keys)
          properties_type.defaults.reject { |k,v| keys.include?(k) }.each do |name,value|
            should "leave the value of #{ name } as default" do
              assert_equal(value, subject.send(name))
            end
          end
        end

        def should_default_everything(properties_type)
          self.should_default_everything_but(properties_type)
        end
      end
    end
  end
end
