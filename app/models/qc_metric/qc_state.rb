# frozen_string_literal: true
module QcMetric::QcState # rubocop:todo Style/Documentation
  State = Struct.new(:name, :automatic, :passed, :proceedable)

  def new_state(name, options = {})
    @states ||= {}
    @states[name] =
      State.new(name, options.fetch(:automatic, true), options.fetch(:passed, true), options.fetch(:proceedable, true))
  end

  def valid_states
    @states.keys
  end

  def qc_state_object_called(name)
    @states[name]
  end
end
