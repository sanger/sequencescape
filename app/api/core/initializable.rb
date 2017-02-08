# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Core::Initializable
  class Initializer
    def initialize(owner)
      @owner = owner
    end

    class << self
      def delegated_attribute_writer(*names)
        names.each do |name|
          class_eval("def #{name}=(value) ; @owner.instance_variable_set(:@#{name}, value) ; end")
        end
        delegate_to_owner(*names)
      end

      def delegate_to_owner(*names)
        names.push(to: :@owner)
        delegate(*names)
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
