Given /^for asset "([^\"]+)" a qc state "([^\"]+)"$/ do |asset_name, qc_state|
  asset = Asset.find_by_name(asset_name) or raise StandardError, "Cannot find asset #{ asset_name. inspect}"
  asset.qc_state = qc_state
  asset.save
end
