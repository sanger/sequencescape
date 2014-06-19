module SetupLibraryTypes
  def self.existing_associations_for(request_type)
    {
      "LibraryCreationRequest"=>["No PCR", "High complexity and double size selected", "Illumina cDNA protocol", "Agilent Pulldown", "Custom", "High complexity", "ChiP-seq", "NlaIII gene expression", "Standard", "Long range", "Small RNA", "Double size selected", "DpnII gene expression", "TraDIS", "qPCR only", "Pre-quality controlled", "DSN_RNAseq", "RNA-seq dUTP"],
      "MultiplexedLibraryCreationRequest"=>["No PCR", "High complexity and double size selected", "Illumina cDNA protocol", "Agilent Pulldown", "Custom", "High complexity", "ChiP-seq", "NlaIII gene expression", "Standard", "Long range", "Small RNA", "Double size selected", "DpnII gene expression", "TraDIS", "qPCR only", "Pre-quality controlled", "DSN_RNAseq", "RNA-seq dUTP"],
      "Pulldown::Requests::WgsLibraryRequest"=>["Standard"],
      "Pulldown::Requests::ScLibraryRequest"=>["Agilent Pulldown"],
      "Pulldown::Requests::IscLibraryRequest"=>["Agilent Pulldown"],
      "IlluminaB::Requests::StdLibraryRequest"=>["No PCR", "High complexity and double size selected", "Illumina cDNA protocol", "Agilent Pulldown", "Custom", "High complexity", "ChiP-seq", "NlaIII gene expression", "Standard", "Long range", "Small RNA", "Double size selected", "DpnII gene expression", "TraDIS", "qPCR only", "Pre-quality controlled", "DSN_RNAseq"],
      "IlluminaHtp::Requests::SharedLibraryPrep"=>["No PCR", "High complexity and double size selected", "Illumina cDNA protocol", "Agilent Pulldown", "Custom", "High complexity", "ChiP-seq", "NlaIII gene expression", "Standard", "Long range", "Small RNA", "Double size selected", "DpnII gene expression", "TraDIS", "qPCR only", "Pre-quality controlled", "DSN_RNAseq"],
      "IlluminaHtp::Requests::LibraryCompletion"=>["No PCR", "High complexity and double size selected", "Illumina cDNA protocol", "Agilent Pulldown", "Custom", "High complexity", "ChiP-seq", "NlaIII gene expression", "Standard", "Long range", "Small RNA", "Double size selected", "DpnII gene expression", "TraDIS", "qPCR only", "Pre-quality controlled", "DSN_RNAseq"],
      "Pulldown::Requests::IscLibraryRequestPart"=>["Agilent Pulldown"],
      "IlluminaC::Requests::PcrLibraryRequest"=>["Manual Standard WGS (Plate)", "ChIP-Seq Auto", "TruSeq mRNA (RNA Seq)", "Small RNA (miRNA)", "RNA-seq dUTP eukaryotic", "RNA-seq dUTP prokaryotic"],
      "IlluminaC::Requests::NoPcrLibraryRequest"=>["No PCR (Plate)"]
    }.tap {|h| h.default = [] }[request_type.request_class_name]
  end

  def self.existing_defaults_for(request_type)
    {
      "LibraryCreationRequest"=>"Standard",
     "MultiplexedLibraryCreationRequest"=>"Standard",
     "Pulldown::Requests::WgsLibraryRequest"=>"Standard",
     "Pulldown::Requests::ScLibraryRequest"=>"Agilent Pulldown",
     "Pulldown::Requests::IscLibraryRequest"=>"Agilent Pulldown",
     "IlluminaB::Requests::StdLibraryRequest"=>"Standard",
     "IlluminaHtp::Requests::SharedLibraryPrep"=>"Standard",
     "IlluminaHtp::Requests::LibraryCompletion"=>"Standard",
     "Pulldown::Requests::IscLibraryRequestPart"=>"Agilent Pulldown",
     "IlluminaC::Requests::PcrLibraryRequest"=>"Manual Standard WGS (Plate)",
     "IlluminaC::Requests::NoPcrLibraryRequest"=>"No PCR (Plate)"
   }[request_type.request_class_name]
  end
end
LibraryType.create!([
  "No PCR", "High complexity and double size selected", "Illumina cDNA protocol",
  "Agilent Pulldown", "Custom", "High complexity", "ChiP-seq", "NlaIII gene expression",
  "Standard", "Long range", "Small RNA", "Double size selected", "DpnII gene expression",
  "TraDIS", "qPCR only", "Pre-quality controlled", "DSN_RNAseq", "RNA-seq dUTP",
  "Manual Standard WGS (Plate)", "ChIP-Seq Auto", "TruSeq mRNA (RNA Seq)", "Small RNA (miRNA)",
  "RNA-seq dUTP eukaryotic", "RNA-seq dUTP prokaryotic", "No PCR (Plate)"
].map {|name| {:name=>name} })

RequestType.find_each do |request_type|

  library_types = LibraryType.find_all_by_name(SetupLibraryTypes.existing_associations_for(request_type))

  if library_types.present?
    library_types.each do |library_type|
      LibraryTypesRequestType.create!(:request_type=>request_type,:library_type=>library_type,:is_default=>library_type.name == SetupLibraryTypes.existing_defaults_for(request_type))
    end
    RequestType::Validator.create!(:request_type=>request_type,:request_option=>'library_type',:valid_options=>RequestType::Validator::LibraryTypeValidator.new(request_type.id))
  end

    # By Key
    read_lengths = {
      'illumina_a_hiseq_2500_paired_end_sequencing' => [75,100],
      'illumina_b_hiseq_2500_paired_end_sequencing' => [75,100],
      'illumina_c_hiseq_2500_paired_end_sequencing' => [75,100],
      'illumina_a_hiseq_2500_single_end_sequencing' => [50],
      'illumina_b_hiseq_2500_single_end_sequencing' => [50],
      'illumina_c_hiseq_2500_single_end_sequencing' => [50]
      }[request_type.key]||{
    # By request class
      'HiSeqSequencingRequest' => [50, 75, 100],
      'MiSeqSequencingRequest' => [25, 50, 130, 150, 250, 300],
      'SequencingRequest'      => [37, 54, 76, 108]
    }[request_type.request_class_name]

  if read_lengths.present?
    RequestType::Validator.create!(:request_type=>request_type,:request_option=>'read_length',:valid_options=>read_lengths)
  end
end
