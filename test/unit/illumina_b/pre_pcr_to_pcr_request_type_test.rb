require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class IlluminaB::PrePcrToPcrRequestTypeTest < ActiveSupport::TestCase
  extend IlluminaB::RequestStatemachineChecks

  state_machine(IlluminaB::Requests::PrePcrToPcr) do
    check_event(:start_fx!, :pending)
    check_event(:start_mj!, :started_fx)
    check_event(:pass!, :pending, :started_mj, :failed)
    check_event(:fail!, :pending, :started_fx, :started_mj, :passed)
    check_event(:cancel!, :started_fx, :started_mj)
  end
end
