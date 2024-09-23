# frozen_string_literal: true

# NOTE: The UUIDs for the requests are generated as sequential numbers from the study UUID
# rubocop:todo Metrics/MethodLength, Metrics/AbcSize, Metrics/ParameterLists
def create_request(request_type, study, project, asset, target_asset, additional_options = {})
  # rubocop:enable Metrics/ParameterLists
  request =
    FactoryBot.create(
      :request_with_submission,
      additional_options.merge(study:, project:, asset:, target_asset:, request_type:)
    )
  request.id = additional_options[:id] if additional_options.key?(:id) # Force ID hack!

  # should be on target asset when we'll use target_asset
  asset.aliquots.each { |a| a.update!(study_id: study.id) }

  # The UUID for the requests needs to be sequentially generated from the study UUID
  uuid_parts = study.uuid.match(/^(.+)-([\da-f]{12})$/) or raise StandardError, "UUID invalid (#{study.uuid.inspect})"
  uuid_root, uuid_index = uuid_parts[1], uuid_parts[2].to_i(0x10)

  Request
    .where(initial_study_id: study.id)
    .order(:id)
    .each_with_index do |request, index|
      request.uuid_object.tap do |uuid|
        uuid.external_id = "#{uuid_root}-%012x" % (uuid_index + 1 + index)
        uuid.save(validate: false)
      end
    end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# rubocop:todo Layout/LineLength
Given /^the (sample|library) tube "([^"]+)" has been involved in a "([^"]+)" request within the study "([^"]+)" for the project "([^"]+)"$/ do |tube_type, tube_name, request_type_name, study_name, project_name|
  # rubocop:enable  Layout/LineLength
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"
  project = Project.find_by(name: project_name) or
    raise StandardError, "Cannot find the project named #{project_name.inspect}"
  request_type = RequestType.find_by(name: request_type_name) or
    raise StandardError, "Cannot find request type #{request_type_name.inspect}"
  asset = "#{tube_type}_tube".camelize.constantize.find_by(name: tube_name) or
    raise StandardError, "Cannot find #{tube_type} tube named #{tube_name.inspect}"
  target_asset = FactoryBot.create(request_type.asset_type.underscore, name: "#{study_name} - Target asset")

  create_request(request_type, study, project, asset, target_asset)
end

# rubocop:todo Layout/LineLength
Given /^I have already made a "([^"]+)" request within the study "([^"]+)" for the project "([^"]+)"$/ do |type, study_name, project_name|
  # rubocop:enable Layout/LineLength
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"
  project = Project.find_by(name: project_name) or
    raise StandardError, "Cannot find the project named #{project_name.inspect}"
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"
  asset = FactoryBot.create(request_type.asset_type.underscore, name: "#{study_name} - Source asset")
  target_asset = FactoryBot.create(request_type.asset_type.underscore, name: "#{study_name} - Target asset")

  create_request(request_type, study, project, asset, target_asset)
end

# rubocop:todo Layout/LineLength
Given /^I have already made (\d+) "([^"]+)" requests? with IDs starting at (\d+) within the study "([^"]+)" for the project "([^"]+)"$/ do |count, type, id, study_name, project_name|
  # rubocop:enable Layout/LineLength
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study named #{study_name.inspect}"
  project = Project.find_by(name: project_name) or
    raise StandardError, "Cannot find the project named #{project_name.inspect}"
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"

  (0...count.to_i).each do |index|
    asset = FactoryBot.create(request_type.asset_type.underscore, name: "#{study_name} - Source asset #{index + 1}")
    target_asset =
      FactoryBot.create(request_type.asset_type.underscore, name: "#{study_name} - Target asset #{index + 1}")
    create_request(request_type, study, project, asset, target_asset, id: id.to_i + index)
  end
end

# rubocop:todo Layout/LineLength
Given /^I have already made a "([^"]+)" request with ID (\d+) within the study "([^"]+)" for the project "([^"]+)"$/ do |type, id, study_name, project_name|
  # rubocop:enable Layout/LineLength
  step(
    # rubocop:todo Layout/LineLength
    "I have already made 1 \"#{type}\" request with IDs starting at #{id} within the study \"#{study_name}\" for the project \"#{project_name}\""
    # rubocop:enable Layout/LineLength
  )
end

Given '{study_name} has an asset group of {int} samples in SampleTubes called {string}' do |study, count, group_name|
  assets =
    (1..count).map do |i|
      sample_name = "#{group_name} sample #{i}".gsub(/\s+/, '_').downcase
      tube_name = "#{group_name}, sample tube #{i}"
      FactoryBot.create(:sample_tube, name: tube_name, sample_attributes: { name: sample_name })
    end
  FactoryBot.create(:asset_group, name: group_name, study:, assets: assets.map(&:receptacle))
end

Then /^I should see the following request information:$/ do |expected|
  # The request info is actually a series of tables. fetch_table just grabs the first.
  # This is silly, but attempting to fix it is probably more hassle than its worth.
  actual = page.all('.property_group_general tr').to_h { |row| row.all('td').map(&:text) }
  assert_equal expected.rows_hash, actual
end
