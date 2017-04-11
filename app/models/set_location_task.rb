# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class SetLocationTask < Task
  set_subclass_attribute :acts_on_input, kind: :bool, default: false, display_name: 'Set location of input assets if ticked (output otherwise)'
  set_subclass_attribute :location_id, cast: :int, default: 4, kind: :selection, display_name: 'Choose default location', choices: -> { Location.all.map { |l| [l.name, l.id] } }

  def partial
    'set_location'
  end

  def do_task(workflow, params)
    workflow.do_set_location_task(self, params)
  end

  def set_location(asset, location_id)
    asset = Asset.find(asset) unless asset.is_a? Asset
    asset.location_id = location_id
    asset.save
  end
end
