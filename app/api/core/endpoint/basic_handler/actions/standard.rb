# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Actions::Standard
  def self.extended(base)
    base.class_eval do
      include InstanceMethods

      class_attribute :standard_actions, instance_writer: false
      self.standard_actions = {}
    end
  end

  def standard_action(*names)
    self.standard_actions = {} if standard_actions.empty?
    standard_actions.merge!(names.to_h { |a| [a.to_sym, a.to_sym] })
  end

  module InstanceMethods
    def standard_update!(request, _)
      request.update!
    end
    private :standard_update!

    def standard_create!(request, _)
      request.create!
    end
    private :standard_create!
  end
end
