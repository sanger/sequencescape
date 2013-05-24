ActiveRecord::Base.transaction do
  IlluminaC::PlatePurposes.create_plate_purposes
  IlluminaC::PlatePurposes.create_tube_purposes
  IlluminaC::PlatePurposes.create_branches
  IlluminaC::Requests.create_request_types
end
