# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

# NOTE: The UUIDs for the requests are generated as sequential numbers from the study UUID
def create_request(request_type, study, project, asset, target_asset, additional_options = {})
  request = FactoryGirl.create(:request,
    additional_options.merge(
      study: study, project: project,
      asset: asset,
      target_asset: target_asset,
      request_type: request_type,
      request_metadata_attributes: {
        fragment_size_required_to: 1,
        fragment_size_required_from: 999,
        library_type: 'Standard',
        read_length: (request_type.request_class == HiSeqSequencingRequest ? 50 : 76)
      }
    )
  )
  request.id = additional_options[:id] if additional_options.key?(:id) # Force ID hack!

  # should be on target asset when we'll use target_asset
  asset.aliquots.each do |a|
    a.update_attributes!(study_id: study.id)
  end

  # The UUID for the requests needs to be sequentially generated from the study UUID
  uuid_parts = study.uuid.match(/^(.+)-([\da-f]{12})$/) or raise StandardError, "UUID invalid (#{study.uuid.inspect})"
  uuid_root, uuid_index = uuid_parts[1], uuid_parts[2].to_i(0x10)

  Request.where(initial_study_id: study.id).order(:id).each_with_index do |request, index|
    request.uuid_object.tap do |uuid|
      uuid.external_id = "#{uuid_root}-%012x" % (uuid_index + 1 + index)
      uuid.save(validate: false)
    end
  end
end

Given /^the (sample|library) tube "([^\"]+)" has been involved in a "([^\"]+)" request within the study "([^\"]+)" for the project "([^\"]+)"$/ do |tube_type, tube_name, request_type_name, study_name, project_name|
  study        = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"
  project      = Project.find_by(name: project_name) or raise StandardError, "Cannot find the project named #{project_name.inspect}"
  request_type = RequestType.find_by(name: request_type_name) or raise StandardError, "Cannot find request type #{request_type_name.inspect}"
  asset = "#{tube_type}_tube".camelize.constantize.find_by(name: tube_name) or raise StandardError, "Cannot find #{tube_type} tube named #{tube_name.inspect}"
  target_asset = FactoryGirl.create(request_type.asset_type.underscore, name: "#{study_name} - Target asset")

  create_request(request_type, study, project, asset, target_asset)
end

Given /^I have already made a "([^\"]+)" request within the study "([^\"]+)" for the project "([^\"]+)"$/ do |type, study_name, project_name|
  study        = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"
  project      = Project.find_by(name: project_name) or raise StandardError, "Cannot find the project named #{project_name.inspect}"
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"
  asset = FactoryGirl.create(request_type.asset_type.underscore, name: "#{study_name} - Source asset")
  target_asset = FactoryGirl.create(request_type.asset_type.underscore, name: "#{study_name} - Target asset")

  create_request(request_type, study, project, asset, target_asset)
end

Given /^I have already made (\d+) "([^\"]+)" requests? with IDs starting at (\d+) within the study "([^\"]+)" for the project "([^\"]+)"$/ do |count, type, id, study_name, project_name|
  study        = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"
  project      = Project.find_by(name: project_name) or raise StandardError, "Cannot find the project named #{project_name.inspect}"
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"

  (0...count.to_i).each do |index|
    asset = FactoryGirl.create(request_type.asset_type.underscore, name: "#{study_name} - Source asset #{index + 1}")
    target_asset = FactoryGirl.create(request_type.asset_type.underscore, name: "#{study_name} - Target asset #{index + 1}")
    create_request(request_type, study, project, asset, target_asset, id: id.to_i + index)
  end
end

Given /^I have already made a "([^\"]+)" request with ID (\d+) within the study "([^\"]+)" for the project "([^\"]+)"$/ do |type, id, study_name, project_name|
  step(%Q{I have already made 1 "#{type}" request with IDs starting at #{id} within the study "#{study_name}" for the project "#{project_name}"})
end

Given /^the sample in (well|sample tube) "([^\"]+)" is registered under the study "([^\"]+)"$/ do |_, asset_name, study_name|
  asset = Asset.find_by(name: asset_name) or raise StandardError, "Cannot find asset #{tube_name.inspect}"
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  study.samples << asset.aliquots.map(&:sample)
end

Given /^the sample in the last (well|sample tube) is registered under the study "([^\"]+)"$/ do |_, study_name|
  asset = Asset.last or raise StandardError, "Cannot find asset #{tube_name.inspect}"
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  study.samples << asset.aliquots.map(&:sample)
end

Given /^the study "([^\"]+)" has an asset group of (\d+) samples called "([^\"]+)"$/ do |study_name, count, group_name|
  step(%Q{the study "#{study_name}" has an asset group of #{count} samples in "sample tube" called "#{group_name}"})
end

Given /^the study "([^\"]+)" has an asset group of (\d+) samples in "([^\"]+)" called "([^\"]+)"$/ do |study_name, count, asset_type, group_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"

  assets = (1..count.to_i).map do |i|
    sample_name = "#{group_name} sample #{i}".gsub(/\s+/, '_').downcase
    param = asset_type == 'well' ? { id: 90 + i } : { name: "#{group_name}, #{asset_type} #{i}" }
    FactoryGirl.create(asset_type.gsub(/[^a-z0-9_-]+/, '_'), param).tap do |asset|
      if asset.primary_aliquot.present?
        asset.primary_aliquot.sample.tap { |s| s.name = sample_name; s.save(validate: false); s.studies << study }
      else
        asset.aliquots.create!(sample: FactoryGirl.create(:sample, name: sample_name), study: study)
        asset.aliquots.each { |a| study.samples << a.sample }
      end
    end
  end
  asset_group = FactoryGirl.create(:asset_group, name: group_name, study: study, assets: assets)
end
Then /^I should see the submission request types of:$/ do |list|
  list.raw.each do |row|
    assert(page.has_css?('#request_types_for_submission li', text: row.first), "Expected row with #{row.first.inspect}")
  end
end

Given /^the last "pending" submission is made$/ do
  submission = Submission.last(conditions: { state: 'pending' }) or raise StandardError, "There are no 'pending' submissions"
  submission.finalize_build!
end

Then /^I should see the following request information:$/ do |expected|
  # The request info is actually a series of tables. fetch_table just grabs the first.
  # This is silly, but attempting to fix it is probably more hassle than its worth.
  actual = Hash[page.all('.info .property_group_general tr').map { |row| row.all('td').map(&:text) }]
  assert_equal expected.rows_hash, actual
end

Given /^all of the wells are on a "([^\"]+)" plate$/ do |plate_purpose_name|
  plate_purpose = PlatePurpose.find_by(name: plate_purpose_name) or raise StandardError, "Cannot find plate purpose #{plate_purpose_name.inspect}"
  plate_purpose.create!(true, barcode: 'random_plate').wells << Well.all
end
