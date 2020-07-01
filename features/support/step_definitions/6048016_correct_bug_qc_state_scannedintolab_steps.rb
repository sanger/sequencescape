# frozen_string_literal: true

Given /^for asset "([^"]+)" a qc state "([^"]+)"$/ do |asset_name, qc_state|
  asset = Labware.find_by(name: asset_name) or raise StandardError, "Cannot find asset #{asset_name.inspect}"
  asset.qc_state = qc_state
  asset.receptacle.save!
end
