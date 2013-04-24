class AddRnaSeqDutpToIlluminaCSubmissionTemplates < ActiveRecord::Migration
  def self.targets
    [
      'Illumina-C - Library creation - Single ended sequencing',
      'Illumina-C - Library creation - Paired end sequencing',
      'Illumina-C - Library creation - HiSeq Paired end sequencing',
      'Illumina-C - Multiplexed library creation - Single ended sequencing',
      'Illumina-C - Multiplexed library creation - Paired end sequencing',
      'Illumina-C - Multiplexed library creation - HiSeq Paired end sequencing',
      'Illumina-C - Multiplexed library creation - HiSeq Single ended sequencing',
      'Illumina-C - Library creation - HiSeq Single ended sequencing',
      'Illumina-C - Library creation - MiSeq sequencing',
      'Illumina-C - Multiplexed library creation - MiSeq sequencing',
      'Illumina-C - Library creation - HiSeq 2500 Paired end sequencing',
      'Illumina-C - Multiplexed library creation - HiSeq 2500 Paired end sequencing',
      'Illumina-C - Library creation - HiSeq 2500 Single end sequencing',
      'Illumina-C - Multiplexed library creation - HiSeq 2500 Single end sequencing'
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do
      selection_options_in(targets) do |option|
        option << "RNA-seq dUTP" unless option.include?("RNA-seq dUTP")
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      selection_options_in(targets) do |option|
        option.delete("RNA-seq dUTP")
      end
    end
  end

  def self.selection_options_in(targets)
    targets.each do |name|
      submission_template = SubmissionTemplate.find_by_name(name) or next
      field_infos = submission_template.submission_parameters[:input_field_infos] or next
      library_types = field_infos.detect {|field| field.display_name == 'Library type'} or next
      yield library_types.parameters[:selection]
      submission_template.save!
    end
  end
end
