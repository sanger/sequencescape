class ::Endpoints::Batches < ::Core::Endpoint::Base
  module StateMachineActions
    def state_action(name, options)
      line = __LINE__ + 1
      instance_eval(%Q{
        bind_action(:update, :as => #{name.to_sym.inspect}, :to => #{name.to_s.inspect}) do |request, response|
          ActiveRecord::Base.transaction do
            request.target.tap do |batch|
              batch.#{name}!(request.user)
            end
          end
        end
        bound_action_guard(#{name.to_sym.inspect}, :update) { |guard| guard.authorised? and #{options[:guard]} }
      }, __FILE__, line)
    end
  end

  model do

  end

  instance do
    belongs_to(:pipeline, :json => "pipeline")

    action(:update, :to => :standard_update!)
    action_guard(:update) { |guard| guard.authorised? and not guard.finished? }

    extend StateMachineActions
    state_action(:start,    :guard => 'guard.pending?')
    state_action(:release,  :guard => 'not guard.released?')
    state_action(:complete, :guard => 'not guard.finished?')
  end
end
