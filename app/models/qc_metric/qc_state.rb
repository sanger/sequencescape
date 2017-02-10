# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module QcMetric::QcState
  State = Struct.new(:name, :automatic, :passed, :proceedable)

  def new_state(name, options = {})
    @states ||= {}
    @states[name] = State.new(name, options.fetch(:automatic, true), options.fetch(:passed, true), options.fetch(:proceedable, true))
  end

  def valid_states
    @states.keys
  end

  def qc_state_object_called(name)
    @states[name]
  end
end
