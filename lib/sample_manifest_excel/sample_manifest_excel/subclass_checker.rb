module SubclassChecker
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def has_subclasses(*classes)
      options = classes.extract_options!
      classes.each do |klass|
        object_type = if options[:modual]
                        "#{options[:modual]}::#{klass.to_s.classify}"
                      else
                        (klass.to_s.classify).to_s
                      end
        define_method "#{klass}?" do
          type == object_type
        end
      end
    end
  end
end
