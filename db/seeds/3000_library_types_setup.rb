# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015,2016 Genome Research Ltd.

module SetupLibraryTypes
  def self.existing_associations_for(request_type)
    {
      'LibraryCreationRequest' => ['No PCR', 'High complexity and double size selected', 'Illumina cDNA protocol', 'Agilent Pulldown', 'Custom', 'High complexity', 'ChiP-seq', 'NlaIII gene expression', 'Standard', 'Long range', 'Small RNA', 'Double size selected', 'DpnII gene expression', 'TraDIS', 'qPCR only', 'Pre-quality controlled', 'DSN_RNAseq', 'RNA-seq dUTP'],
      'MultiplexedLibraryCreationRequest' => ['No PCR', 'High complexity and double size selected', 'Illumina cDNA protocol', 'Agilent Pulldown', 'Custom', 'High complexity', 'ChiP-seq', 'NlaIII gene expression', 'Standard', 'Long range', 'Small RNA', 'Double size selected', 'DpnII gene expression', 'TraDIS', 'qPCR only', 'Pre-quality controlled', 'DSN_RNAseq', 'RNA-seq dUTP'],
      'Pulldown::Requests::WgsLibraryRequest' => ['Standard'],
      'Pulldown::Requests::ScLibraryRequest' => ['Agilent Pulldown'],
      'Pulldown::Requests::IscLibraryRequest' => ['Agilent Pulldown'],
      'IlluminaB::Requests::StdLibraryRequest' => ['No PCR', 'High complexity and double size selected', 'Illumina cDNA protocol', 'Agilent Pulldown', 'Custom', 'High complexity', 'ChiP-seq', 'NlaIII gene expression', 'Standard', 'Long range', 'Small RNA', 'Double size selected', 'DpnII gene expression', 'TraDIS', 'qPCR only', 'Pre-quality controlled', 'DSN_RNAseq'],
      'IlluminaHtp::Requests::SharedLibraryPrep' => ['No PCR', 'High complexity and double size selected', 'Illumina cDNA protocol', 'Agilent Pulldown', 'Custom', 'High complexity', 'ChiP-seq', 'NlaIII gene expression', 'Standard', 'Long range', 'Small RNA', 'Double size selected', 'DpnII gene expression', 'TraDIS', 'qPCR only', 'Pre-quality controlled', 'DSN_RNAseq'],
      'IlluminaHtp::Requests::LibraryCompletion' => ['No PCR', 'High complexity and double size selected', 'Illumina cDNA protocol', 'Agilent Pulldown', 'Custom', 'High complexity', 'ChiP-seq', 'NlaIII gene expression', 'Standard', 'Long range', 'Small RNA', 'Double size selected', 'DpnII gene expression', 'TraDIS', 'qPCR only', 'Pre-quality controlled', 'DSN_RNAseq'],
      'Pulldown::Requests::IscLibraryRequestPart' => ['Agilent Pulldown'],
      'IlluminaC::Requests::PcrLibraryRequest' => ['Manual Standard WGS (Plate)', 'ChIP-Seq Auto', 'TruSeq mRNA (RNA Seq)', 'Small RNA (miRNA)', 'RNA-seq dUTP eukaryotic', 'RNA-seq dUTP prokaryotic'],
      'IlluminaC::Requests::NoPcrLibraryRequest' => ['No PCR (Plate)']
    }.tap { |h| h.default = [] }[request_type.request_class_name]
  end

  def self.existing_defaults_for(request_type)
    {
      'LibraryCreationRequest' => 'Standard',
      'MultiplexedLibraryCreationRequest' => 'Standard',
      'Pulldown::Requests::WgsLibraryRequest' => 'Standard',
      'Pulldown::Requests::ScLibraryRequest' => 'Agilent Pulldown',
      'Pulldown::Requests::IscLibraryRequest' => 'Agilent Pulldown',
      'IlluminaB::Requests::StdLibraryRequest' => 'Standard',
      'IlluminaHtp::Requests::SharedLibraryPrep' => 'Standard',
      'IlluminaHtp::Requests::LibraryCompletion' => 'Standard',
      'Pulldown::Requests::IscLibraryRequestPart' => 'Agilent Pulldown',
      'IlluminaC::Requests::PcrLibraryRequest' => 'Manual Standard WGS (Plate)',
      'IlluminaC::Requests::NoPcrLibraryRequest' => 'No PCR (Plate)'
   }[request_type.request_class_name]
  end
end
LibraryType.create!([
  'No PCR', 'High complexity and double size selected', 'Illumina cDNA protocol',
  'Agilent Pulldown', 'Custom', 'High complexity', 'ChiP-seq', 'NlaIII gene expression',
  'Standard', 'Long range', 'Small RNA', 'Double size selected', 'DpnII gene expression',
  'TraDIS', 'qPCR only', 'Pre-quality controlled', 'DSN_RNAseq', 'RNA-seq dUTP',
  'Manual Standard WGS (Plate)', 'ChIP-Seq Auto', 'TruSeq mRNA (RNA Seq)', 'Small RNA (miRNA)',
  'RNA-seq dUTP eukaryotic', 'RNA-seq dUTP prokaryotic', 'No PCR (Plate)'
].map { |name| { name: name } })

RequestType.find_each do |request_type|
  library_types = LibraryType.where(name: SetupLibraryTypes.existing_associations_for(request_type))

  if library_types.present?
    library_types.each do |library_type|
      LibraryTypesRequestType.create!(request_type: request_type, library_type: library_type, is_default: library_type.name == SetupLibraryTypes.existing_defaults_for(request_type))
    end
    RequestType::Validator.create!(request_type: request_type, request_option: 'library_type', valid_options: RequestType::Validator::LibraryTypeValidator.new(request_type.id))
  end

    # By Key
    read_lengths = {
      'illumina_a_hiseq_2500_paired_end_sequencing' => [75, 100],
      'illumina_b_hiseq_2500_paired_end_sequencing' => [75, 100],
      'illumina_c_hiseq_2500_paired_end_sequencing' => [75, 100],
      'illumina_a_hiseq_2500_single_end_sequencing' => [50],
      'illumina_b_hiseq_2500_single_end_sequencing' => [50],
      'illumina_c_hiseq_2500_single_end_sequencing' => [50],
      'illumina_a_hiseq_v4_paired_end_sequencing' => [75, 125],
      'illumina_b_hiseq_v4_paired_end_sequencing' => [75, 125],
      'illumina_c_hiseq_v4_paired_end_sequencing' => [75, 125],
      'illumina_c_hiseq_v4_single_end_sequencing' => [19, 50],
      'illumina_a_hiseq_x_paired_end_sequencing' => [150],
      'illumina_b_hiseq_x_paired_end_sequencing' => [150],
      'bespoke_hiseq_x_paired_end_sequencing' => [150]
      }[request_type.key] || {
      # By request class
      'HiSeqSequencingRequest' => [50, 75, 100],
      'MiSeqSequencingRequest' => [25, 50, 130, 150, 250, 300],
      'SequencingRequest'      => [37, 54, 76, 108]
    }[request_type.request_class_name]

  if read_lengths.present?
    RequestType::Validator.create!(request_type: request_type, request_option: 'read_length', valid_options: read_lengths)
  end
end

['a', 'b', 'c'].each do |pipeline|
  rt = RequestType.find_by(key: "illumina_#{pipeline}_hiseq_v4_paired_end_sequencing")
  RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [125, 75])
end

rt = RequestType.find_by(key: 'illumina_c_hiseq_v4_single_end_sequencing')
RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [29, 50])

## New library types Illumina C
library_types = LibraryType.create!([
  'TraDIS qPCR only', 'Transcriptome counting qPCR only', 'Nextera single index qPCR only',
  'Nextera dual index qPCR only', 'Bisulphate qPCR only', 'TraDIS pre quality controlled',
  'Transcriptome counting pre quality controlled', 'Nextera single index pre quality controlled',
  'Nextera dual index pre quality controlled', 'Bisulphate pre quality controlled'].map { |name| { name: name } })

[:illumina_c_multiplexed_library_creation, :illumina_c_library_creation].each do |request_class_symbol|
  request_type = RequestType.find_by(key: request_class_symbol.to_s)
  library_types.each do |library_type|
    LibraryTypesRequestType.create!(request_type: request_type, library_type: library_type, is_default: false)
  end
end

libs_ribozero = ['Ribozero RNA-seq (Bacterial)', 'Ribozero RNA-seq (HMR)'].map do |name|
  LibraryType.create!(name: name)
end

libs_ribozero.each do |lib|
  [:illumina_c_pcr, :illumina_c_pcr_no_pool].each do |request_class_symbol|
    request_type = RequestType.find_by(key: request_class_symbol.to_s)
    LibraryTypesRequestType.create!(request_type: request_type, library_type: lib, is_default: false)
  end
end

RequestType.find_by(key: 'illumina_c_chromium_library').library_types = LibraryType.create!(['Chromium genome', 'Chromium exome', 'Chromium single cell'].map { |name| { name: name } })
RequestType::Validator.create!(
  request_type: RequestType.find_by(key: 'illumina_c_chromium_library'),
  request_option: 'library_type',
  valid_options: RequestType::Validator::LibraryTypeValidator.new(RequestType.find_by(key: 'illumina_c_chromium_library').id)
)
# PCR Free Hiseq X10 RequestTypeValidator
lt = LibraryType.find_or_create_by(name: 'HiSeqX PCR free')
rt_pf = RequestType.find_by(key: 'htp_pcr_free_lib')
rt_v = RequestType::Validator.create!(
  request_type: rt_pf,
  request_option: 'library_type',
  valid_options: RequestType::Validator::LibraryTypeValidator.new(rt_pf.id)
)

['a', 'b'].each do |pipeline|
  rt = RequestType.find_by!(key: "illumina_#{pipeline}_hiseq_x_paired_end_sequencing")
  RequestType::Validator.create!(request_type: rt, request_option: 'read_length', valid_options: [150])
  rt.library_types << LibraryType.find_by(name: 'Standard')
  RequestType::Validator.create!(request_type: rt, request_option: 'library_type', valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id))
  RequestType::Validator.create!(request_type: rt, request_option: 'fragment_size_required_to', valid_options: ['350'])
  RequestType::Validator.create!(request_type: rt, request_option: 'fragment_size_required_from', valid_options: ['350'])
end
