require "test_helper"
require 'unit/tag_qc/qcable_statemachine_checks'

class QcableStatemachineTest < ActiveSupport::TestCase

  extend QcableStatemachineChecks

  state_machine(Qcable) do
    check_event(:do_stamp,   :from => [:created],                 :to => :pending)
    check_event(:destroy, :from => [:pending, :available],     :to => :destroyed)
    check_event(:qc,      :from => [:pending],                 :to => :qc_in_progress)
    check_event(:release, :from => [:pending],                 :to => :available)
    check_event(:pass,    :from => [:qc_in_progress],          :to => :passed)
    check_event(:fail,    :from => [:qc_in_progress,:pending], :to => :failed)
    check_event(:use,     :from => [:available],               :to => :exhausted)
  end

end
