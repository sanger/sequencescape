#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddIlluminaCHiSeqV4SingleEnded < ActiveRecord::Migration

  def self.previous_submission_templates
      [
        "Illumina-C - General PCR - HiSeq v4 sequencing",
        "Illumina-C - General no PCR - HiSeq v4 sequencing",
        "Illumina-C - Library Creation - HiSeq v4 sequencing",
        "Illumina-C - Multiplexed Library Creation - HiSeq v4 sequencing"
      ]
  end

  def self.previous_pipelines
    ["HiSeq v4 PE (spiked in controls)", "HiSeq v4 PE (no controls)"]
  end

  def self.up
    ActiveRecord::Base.transaction do |t|

      request_type = RequestType.find_by_key!("illumina_c_hiseq_v4_paired_end_sequencing").clone.tap do |r|
        r.key = "illumina_c_hiseq_v4_single_end_sequencing"
        r.name = "Illumina-C HiSeq V4 Single End sequencing"

      end

      RequestType::Validator.create!(
        :request_type   => request_type,
        :request_option => 'read_length',
        :valid_options   => [29, 50]
      )

      self.previous_pipelines.map {|n| Pipeline.find_by_name!(n)}.each do |pipeline|
        pipeline.clone.tap do |p|
          p.name.sub!("PE", "SE")
          p.request_types = [request_type]

          workflow = pipeline.workflow.deep_copy("_suf", true)
          workflow.name = p.name
          workflow.tasks = workflow.tasks.reject{|t| t.name == "Read 2 Cluster/Lin/block/hyb/load"}
          workflow.pipeline = p

          p.workflow = workflow
        end.save!
      end

      self.previous_submission_templates.each do |name|
        base_template = SubmissionTemplate.find_by_name!(name)
        template = base_template.clone.tap do |s|
          s.name = name + " SE"
          s.submission_parameters[:request_type_ids_list] = [
            s.submission_parameters[:request_type_ids_list][0],
            [request_type.id]
          ]
        end
        template.save!

        base_template.supercede do |s|
          s.update_attributes!(:name => base_template.name + ' PE')
        end

      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |t|
      request_type = RequestType.find_by_key!("illumina_c_hiseq_v4_single_end_sequencing")
      RequestType::Validator.find_by_request_type_id!(request_type.id).destroy
      request_type.destroy

      self.previous_pipelines.map {|name| name.gsub("PE","SE")}.each do |name|
        Pipeline.find_by_name!(name).destroy
        LabInterface::Workflow.find_by_name(name).destroy
      end
      self.previous_submission_templates.each do |name|
        SubmissionTemplate.find_by_name!(name + " SE").destroy
        SubmissionTemplate.find_by_name!(name + " PE").destroy
      end
    end
  end
end
