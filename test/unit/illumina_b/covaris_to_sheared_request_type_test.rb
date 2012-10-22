require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class IlluminaB::CovarisToShearedRequestTypeTest < ActiveSupport::TestCase
  extend IlluminaB::RequestStatemachineChecks

  state_machine(IlluminaB::Requests::CovarisToSheared) do
    check_event(:start!, :pending)
    check_event(:pass!, :pending, :started, :failed)
    check_event(:qc!, :passed)
    check_event(:fail, :pending, :started, :passed)
    check_event(:cancel, :started)
  end
end
