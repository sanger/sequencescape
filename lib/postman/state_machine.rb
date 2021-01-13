class Postman
  module StateMachine
    module Helper # rubocop:todo Style/Documentation
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
