# frozen_string_literal: true

module Core::Initializable
  class Initializer
    def initialize(owner)
      @owner = owner
    end

    class << self
      def delegated_attribute_writer(*names)
        names.each { |name| class_eval("def #{name}=(value) ; @owner.instance_variable_set(:@#{name}, value) ; end") }
        delegate_to_owner(*names)
      end

      def delegate_to_owner(*names)
        delegate(*names, to: :@owner)
      end
    end
  end

  def self.extended(base)
    base.class_eval do
      include InstanceMethods

      const_set(:Initializer, Class.new(Core::Initializable::Initializer))
    end
  end

  def initialized_attr_reader(*names)
    attr_reader(*names)

    self::Initializer.delegated_attribute_writer(*names)
  end

  def initialized_delegate(*names)
    self::Initializer.delegate_to_owner(*names)
  end

  module InstanceMethods
    def initialize
      yield(self.class::Initializer.new(self)) if block_given?
    end
  end
end
