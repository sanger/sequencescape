

class SetUpAssociations < ActiveRecord::Migration

  class ::LibraryType < ActiveRecord::Base

  end

  class ::LibraryTypesRequestType < ActiveRecord::Base
    belongs_to :request_type
    belongs_to :library_type
  end

  def self.up
    ActiveRecord::Base.transaction do
      say RequestType.count
      RequestType.find_each do |request_type|
        say "Updating #{request_type.name}"
        library_types = LibraryType.find_all_by_name(existing_associations_for(request_type))
        say "Found #{library_types.join(',')}"
        next if library_types.empty?
        library_types.each do |library_type|
          LibraryTypesRequestType.create!(:request_type=>request_type,:library_type=>library_type,:is_default=>library_type.name == existing_defaults_for(request_type))
        end
      end
    end
  end

  def self.down
    # ActiveRecord::Base.transaction do
    #   RequestType.all.each do |request_type|
    #     library_types = LibraryType.find_all_by_name(existing_associations_for(request_type))
    #     next if library_types.empty?
    #     request_type.library_types.delete(library_types)
    #   end
    # end
  end

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
