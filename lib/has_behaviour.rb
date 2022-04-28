# frozen_string_literal: true
# Simple module to provide means of delegating specific behaviours
# to external objects. Allows the behaviours to be safely specified
# in the database. Use of constantize can allow for loading of aribtary
# ruby classes as HasBehaviour::File for instance loads the global file
# object.
module HasBehaviour
  module ClassMethods # rubocop:todo Style/Documentation
    def has_behaviour(klass, behaviour_name: nil)
      @registered_behaviours ||= {}
      @registered_behaviours[behaviour_name || klass.name] = klass
    end

    def has_behaviour?(behaviour_name)
      @registered_behaviours.key?(behaviour_name)
    end

    def with_behaviour(behaviour_name)
      @registered_behaviours.fetch(behaviour_name)
    end

    def registered_behaviours
      @registered_behaviours.keys
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
