# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class AddRequestTypeForPcrFreeXten < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do |_t|
      rt = RequestType.create!(
        name: 'HTP PCR Free Library',
        key: 'htp_pcr_free_lib',
        asset_type: 'Well',
        deprecated: false,
        initial_state: 'pending',
        for_multiplexing: true,
        morphology: 0,
        multiples_allowed: false,
        no_target_asset: false,
        order: 1,
        pooling_method: RequestType::PoolingMethod.find_by!(pooling_behaviour: 'PlateRow'),
        request_purpose: RequestPurpose.find_by!(key: 'standard'),
        request_class_name: 'IlluminaHtp::Requests::StdLibraryRequest',
        workflow: Submission::Workflow.find_by!(key: 'short_read_sequencing'),
        product_line: ProductLine.find_by!(name: 'Illumina-HTP')
        )

      rt.acceptable_plate_purposes << Purpose.find_by!(name: 'PF Cherrypicked')

      lt = LibraryType.find_or_create_by(name: 'HiSeqX PCR free')
      rt_v = RequestType::Validator.create!(
        request_type: rt,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(rt.id)
      )

      RequestType.find_by!(key: 'htp_pcr_free_lib').library_types << lt
      %w(
htp_pcr_free_lib
illumina_htp_strip_tube_creation
illumina_b_hiseq_x_paired_end_sequencing illumina_a_hiseq_x_paired_end_sequencing illumina_b_hiseq_x_paired_end_sequencing).each do |xtlb_name|
        RequestType.find_by(key: xtlb_name).library_types << lt
      end

      st = SubmissionSerializer.construct!(name: 'IHTP - PCR Free Auto - HiSeq-X sequencing',
                                           submission_class_name: 'FlexibleSubmission',
                                           product_line: 'Illumina-HTP',
                                           product_catalogue: 'PFHSqX',
                                           submission_parameters: {
          request_types: [
            'htp_pcr_free_lib',
            'illumina_htp_strip_tube_creation',
            'illumina_b_hiseq_x_paired_end_sequencing'],
          workflow: 'short_read_sequencing'
        })
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |_t|
      hiseqlt = LibraryType.find_by(name: 'HiSeqX PCR free')
      unless hiseqlt.nil?
        ['illumina_a_hiseq_x_paired_end_sequencing', 'illumina_b_hiseq_x_paired_end_sequencing'].each do |rt_name|
          rt = RequestType.find_by(key: rt_name)
          lib_types = rt.library_types
          unless lib_types.nil?
            rt.library_types = lib_types.reject { |lt| lt == hiseqlt }
          end
        end
        hiseqlt.destroy
      end
      SubmissionTemplate.find_by(name: 'IHTP - PCR Free Auto - HiSeq-X sequencing').destroy
      RequestType.find_by(key: 'htp_pcr_free_lib').destroy
    end
  end
end
