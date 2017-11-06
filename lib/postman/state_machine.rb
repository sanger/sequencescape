class Postman
  module StateMachine
    module Helper
      def state(state_name)
        define_method(:"#{state_name}!") { @state = state_name }
        define_method(:"#{state_name}?") { @state == state_name }
      end

      def states(*state_names)
        state_names.each { |state_name| state(state_name) }
      end
    end
  end
end
