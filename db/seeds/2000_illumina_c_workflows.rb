ActiveRecord::Base.transaction do
  IlluminaC::PlatePurposes.create_plate_purposes
  IlluminaC::PlatePurposes.create_tube_purposes
  IlluminaC::PlatePurposes.create_branches
  IlluminaC::Requests.create_request_types

  [
    {:name=>'ChIP Auto PCR',     :role=>'ChIP Auto PCR',   :type=>'illumina_c_pcr'},
    {:name=>'RNAseq Manual PCR', :role=>'RNAseq Man PCR',  :type=>'illumina_c_pcr'},
    {:name=>'RNAseq Auto PCR',   :role=>'RNAseq Auto PCR', :type=>'illumina_c_pcr'},
    {:name=>'FAIRE Auto PCR',    :role=>'FAIRE Auto PCR',  :type=>'illumina_c_pcr'},
    {:name=>'ChIP Auto',         :role=>'ChIP Auto',       :type=>'illumina_c_nopcr'},
    {:name=>'RNAseq Manual',     :role=>'RNAseq Man',      :type=>'illumina_c_nopcr'},
    {:name=>'RNAseq Auto',       :role=>'RNAseq Auto',     :type=>'illumina_c_nopcr'},
    {:name=>'FAIRE Auto',        :role=>'FAIRE Auto',      :type=>'illumina_c_nopcr'},
  ].each do |options|
    IlluminaC::Helper::TemplateConstructor.new(options).build!
  end
end
