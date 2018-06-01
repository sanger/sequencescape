
module Sanger
  module Testing
    module Model
      module Macros
        def should_default_everything_but(properties_type, *keys)
          properties_type.defaults.reject { |k, _v| keys.include?(k) }.each do |name, value|
            should "leave the value of #{name} as default" do
              subject_property_value = subject.send(name)
              if value.nil?
                assert_nil(subject_property_value)
              else
                assert_equal(value, subject_property_value)
              end
            end
          end
        end

        def should_default_everything(properties_type)
          should_default_everything_but(properties_type)
        end
      end
    end
  end
end
