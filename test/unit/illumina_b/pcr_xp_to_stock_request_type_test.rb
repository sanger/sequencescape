#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2014 Genome Research Ltd.
require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class IlluminaB::PcrXpToStockRequestTypeTest < ActiveSupport::TestCase
  extend IlluminaB::RequestStatemachineChecks

  state_machine(IlluminaB::Requests::PcrXpToStock) do
    check_event(:start!, :pending)
    check_event(:pass!, :pending, :started, :failed)
    check_event(:qc!, :passed)
    check_event(:fail, :pending, :started, :passed)
    check_event(:cancel, :started, :passed)
  end
end
