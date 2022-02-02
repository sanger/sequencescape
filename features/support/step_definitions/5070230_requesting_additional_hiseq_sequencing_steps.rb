# frozen_string_literal: true

Given 'I have a library tube called {string}' do |name|
  FactoryBot.create(:empty_library_tube, name: name)
end

Given 'I have already made a request for library tube {string} within {study_name}' do |library_tube_name, study|
  library_tube = LibraryTube.find_by!(name: library_tube_name)
  library_type = LibraryType.find_by(name: 'Standard') || FactoryBot.create(:library_type, name: 'Standard')
  FactoryBot
    .create(:library_creation_request_type, :with_library_types, library_type: library_type)
    .create!(
      asset: library_tube,
      study: study,
      request_metadata_attributes: {
        fragment_size_required_from: 111,
        fragment_size_required_to: 222,
        library_type: 'Standard'
      }
    )
end
