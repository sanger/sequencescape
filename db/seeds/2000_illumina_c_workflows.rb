# frozen_string_literal: true

ActiveRecord::Base.transaction do
  if Rails.env.cucumber?
    RecordLoader::TubePurposeLoader.new(files: [
      '003_illumina_c_legacy_purposes'
    ]).create!
    RecordLoader::PlatePurposeLoader.new(files: [
      '003_illumina_c_legacy_purposes'
    ]).create!
  end
  IlluminaC::Requests.create_request_types
end
