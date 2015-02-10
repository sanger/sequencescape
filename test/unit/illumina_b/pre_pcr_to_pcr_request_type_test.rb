#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2014 Genome Research Ltd.
require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class IlluminaB::PrePcrToPcrRequestTypeTest < ActiveSupport::TestCase
  extend IlluminaB::RequestStatemachineChecks

  state_machine(IlluminaB::Requests::PrePcrToPcr) do
    check_event(:start_fx!, :pending)
    check_event(:start_mj!, :started_fx)
    check_event(:pass!, :pending, :started_mj, :failed)
    check_event(:fail!, :pending, :started_fx, :started_mj, :passed)
    check_event(:cancel!, :started_fx, :started_mj, :passed)
  end
end
