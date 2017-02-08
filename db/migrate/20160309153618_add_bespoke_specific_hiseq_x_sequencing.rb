class AddBespokeSpecificHiseqXSequencing < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      rt = RequestType.create!(
        asset_type: 'LibraryTube',
        billable: true,
        deprecated: false,
        for_multiplexing: false,
        initial_state: 'pending',
        key: 'bespoke_hiseq_x_paired_end_sequencing',
        morphology: 0,
        multiples_allowed: false,
        name: 'Bespoke HiSeq X Paired end sequencing',
        no_target_asset: false,
        order: 2,
        product_line_id: ProductLine.find_by!(name: 'Illumina-C'),
        request_class_name: 'HiSeqSequencingRequest',
        request_purpose: RequestPurpose.standard,
        workflow_id: Submission::Workflow.find_by(key: 'short_read_sequencing')
      )
      ['Standard', 'HiSeqX PCR free', 'qPCR only', 'Pre-quality controlled'].each do |name|
        rt.library_types << LibraryType.find_by!(name: name)
      end
      rt.request_type_validators.build([
        { request_option: 'read_length', valid_options: [150] },
        { request_option: 'library_type', valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id) },
        { request_option: 'fragment_size_required_to', valid_options: ['350', '450'] },
        { request_option: 'fragment_size_required_from', valid_options: ['350', '450'] }
      ])
      rt.save!
      Pipeline.find_by(name: 'HiSeq X PE (spiked in controls)').request_types << rt
      Pipeline.find_by(name: 'HiSeq X PE (no controls)').request_types << rt
    end
  end

  def down
    ActiveRecord::Base.transaction do
      RequestType.find_by!(key: 'bespoke_hiseq_x_paired_end_sequencing').destroy
    end
  end
end
