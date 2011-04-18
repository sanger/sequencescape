module Core::Endpoint::BasicHandler::Actions::Standard
  def self.extended(base)
    base.class_eval do
      include InstanceMethods

      class_inheritable_reader :standard_actions
      write_inheritable_attribute(:standard_actions, {})
    end
  end

  def standard_action(*names)
    standard_actions.merge!(Hash[names.map { |a| [a.to_sym, a.to_sym] }])
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
