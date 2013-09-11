ActiveRecord::Base.transaction do
  IlluminaC::PlatePurposes.create_plate_purposes
  IlluminaC::PlatePurposes.create_tube_purposes
  IlluminaC::PlatePurposes.create_branches
  IlluminaC::Requests.create_request_types

  [
    {:name=>'General PCR',     :role=>'PCR',   :type=>'illumina_c_pcr'},
    {:name=>'General no PCR',  :role=>'PCR',   :type=>'illumina_c_nopcr'},
  ].each do |options|
    IlluminaC::Helper::TemplateConstructor.new(options).build!
  end
end
