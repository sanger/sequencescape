class CorrectSubmissionTemplates < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
       new_templates.each do |new_st|
        each_variant(new_st) do |options|
          template = SubmissionTemplate.find_by_name(options[:name])
          if template.nil?
            say "Couldn't find #{options[:name]}"
            next
          end
          sub_params = template.submission_parameters
          sub_params.delete(:input_field_infos)
          sub_params.merge!(options[:submission_parameters])
          SubmissionTemplate.find_by_name(options[:name]).update_attributes!(:submission_parameters=>sub_params)
        end
      end
    end
  end

  def self.new_templates
    [
      {:middle_name => 'Pippin PATH', :type=>'b'},
      {:middle_name => 'Pooled PATH', :type=>'b'},
      {:middle_name => 'Pippin HWGS', :type=>'b'},
      {:middle_name => 'Pooled HWGS', :type=>'b'},
      {:middle_name => 'HTP ISC',     :type=>'a'}
    ]
  end

  def self.each_variant(new_st)
    [true,false].each do |cherrypick|
      sequencing_requests(new_st[:type]).each do |sequencing_request|
        yield({
          :name => "Illumina-#{new_st[:type].upcase} -#{cherrypick ? 'Cherrypicked -':''} #{new_st[:middle_name]} - #{sequencing_request[:name]}",
          :submission_parameters => sequencing_request[:submission_parameters],
        })
      end
    end
  end

  def self.sequencing_requests(pipeline)
    case pipeline
    when 'a'
      [
        {:name=>'HiSeq 2500 Paired end sequencing', :submission_parameters => Hiseq2500Helper.other(:sub_params=>:sc)},
        {:name=>'HiSeq 2500 Single end sequencing', :submission_parameters => Hiseq2500Helper.other(:sub_params=>:sc)},
        {:name=>'HiSeq Single ended sequencing',    :submission_parameters => Hiseq2500Helper.other(:sub_params=>:sc)}
      ]
    when 'b'
      [
        {:name=>'HiSeq 2500 Paired end sequencing', :submission_parameters => Hiseq2500Helper.other(:sub_params=>:ill_b       )},
        {:name=>'HiSeq 2500 Single end sequencing', :submission_parameters => Hiseq2500Helper.other(:sub_params=>:ill_b_single)},
        {:name=>'HiSeq Single ended sequencing',    :submission_parameters => Hiseq2500Helper.other(:sub_params=>:ill_b_single)}
      ]
   end
  end

  def self.down
  end
end
