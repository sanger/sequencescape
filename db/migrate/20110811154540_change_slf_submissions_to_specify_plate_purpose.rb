#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ChangeSlfSubmissionsToSpecifyPlatePurpose < ActiveRecord::Migration
  TEMPLATES_TO_PICK_FROM_PLATES = [
    "Microarray genotyping",
    "SLFQC - Cherrypicking",
    "Cherrypicking - Genotyping",
    "SLFQC",
    "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing",
    "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - Paired end sequencing",
    "Cherrypick"
  ]

  TEMPLATE_NAMES = [
    "enter a list of sample names",
    "enter a list of sample names found on plates"
  ]

  def self.change_sample_picking_to(current_template, new_template)
    SubmissionTemplate.find_each(:conditions => { :name => TEMPLATES_TO_PICK_FROM_PLATES }) do |template|
      template.submission_parameters[:asset_input_methods].map! { |v| (v == current_template) ? new_template : v }
      template.save!
    end
  end

  def self.up
    change_sample_picking_to(*TEMPLATE_NAMES)
  end

  def self.down
    change_sample_picking_to(*TEMPLATE_NAMES.reverse)
  end
end
