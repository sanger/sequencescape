# frozen_string_literal: true

module SequencescapeExcel
  ##
  # SubclassChecker
  module SubclassChecker
    extend ActiveSupport::Concern

    ##
    # Adds a method to a superclass which can be called in each subclass
    # to check whether it is an object of that class
    # each class must implement the type method.
    # The type method is not part of the module as it can be used by AR objects.
    # The modual option allows namespacing.
    # Example:
    #  modual = My::Namespace
    #  klass = My::Namespace::MySubclass1
    #
    # Example:
    #  def MyClass
    #   subclasses? :my_subclass_1, :my_subclass_2, :my_subclass_3
    #  end
    #  my_subclass_1 = MySubclass1.new
    #  my_subclass_1.my_subclass_1? => true
    #  my_subclass_1.my_subclass_2? => false
    #
    module ClassMethods
      def subclasses?(*classes)
        options = classes.extract_options!
        classes.each do |klass|
          object_type = options[:modual] ? "#{options[:modual]}::#{klass.to_s.classify}" : klass.to_s.classify.to_s
          define_method :"#{klass}?" do
            type == object_type
          end
        end
      end
    end
  end
end
