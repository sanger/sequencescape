#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.
class PopulateRequestTypeValidatorsTable < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_each do |request_type|

        # Add Library Types Validator
        # Note that this only covers the request_options validation,
        # this is a good thing, as we can have extra requirements added to
        # Sequencing Requests, without needing to track extra metadata
        # on the requests themselves.
        if request_type.library_types.present?
          RequestType::Validator.create!(
            :request_type   => request_type,
            :request_option => 'library_type',
            :valid_options  => RequestType::Validator::LibraryTypeValidator.new(request_type.id)
          )
        end

        # Add Read Lengths Validator
        next unless read_lengths_for(request_type).present?

        RequestType::Validator.create!(
          :request_type   => request_type,
          :request_option => 'read_length',
          :valid_options   => read_lengths_for(request_type)
        )

      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType::Validator.destroy_all
    end
  end

  def self.read_lengths_for(request_type)
    return false if [
      'illumina_a_hiseq_v4_paired_end_sequencing',
      'illumina_b_hiseq_v4_paired_end_sequencing',
      'illumina_c_hiseq_v4_paired_end_sequencing',
      'illumina_a_hiseq_x_paired_end_sequencing',
      'illumina_b_hiseq_x_paired_end_sequencing'
    ].include?(request_type.key)
    # By Key
    {
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
  end
end
