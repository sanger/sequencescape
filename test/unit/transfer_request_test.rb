# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015,2016 Genome Research Ltd.

require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class TransferRequestTest < ActiveSupport::TestCase
  # all other tests are in spec

  extend IlluminaB::RequestStatemachineChecks

  state_machine(TransferRequest) do
    check_event(:start!, :pending)
    check_event(:pass!, :pending, :started, :failed)
    check_event(:qc!, :passed)
    check_event(:fail!, :pending, :started, :passed)
    check_event(:cancel!, :started, :passed, :qc_complete)
    check_event(:cancel_before_started!, :pending)
  end
end
