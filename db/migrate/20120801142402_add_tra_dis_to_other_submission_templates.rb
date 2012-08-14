class AddTraDisToOtherSubmissionTemplates < ActiveRecord::Migration

  def self.targets
    [
      # 'Library creation - HiSeq Paired end sequencing',
      # 'Library creation - HiSeq Single ended sequencing',
      # 'Library creation - MiSeq sequencing',
      # 'Multiplexed library creation - HiSeq Paired end sequencing',
      # 'Multiplexed library creation - HiSeq Single ended sequencing',
      # 'Multiplexed library creation - MiSeq sequencing',
      #
      # 'Illumina-B - Multiplexed library creation - HiSeq Paired end sequencing',
      # 'Illumina-B - Multiplexed library creation - HiSeq Single ended sequencing',

      'Illumina-C - Library creation - HiSeq Paired end sequencing',
      'Illumina-C - Library creation - HiSeq Single ended sequencing',
      'Illumina-C - Library creation - MiSeq sequencing',
      'Illumina-C - Multiplexed library creation - HiSeq Paired end sequencing',
      'Illumina-C - Multiplexed library creation - HiSeq Single ended sequencing',
      'Illumina-C - Multiplexed library creation - MiSeq sequencing'
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do
      selection_options_in(targets) do |option|
        option << "TraDIS" unless option.include?("TraDIS")
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      selection_options_in(targets) do |option|
        option.delete("TraDIS")
      end
    end
  end

  def self.selection_options_in(targets)
    targets.each do |name|
      submission_template = SubmissionTemplate.find_by_name(name) or next
      field_infos = submission_template.submission_parameters[:input_field_infos] or next
      library_types = field_infos.detect {|field| field.ivars["display_name"] == 'Library type'} or next
      yield library_types.ivars["parameters"][:selection]
      submission_template.save!
    end
  end
end
