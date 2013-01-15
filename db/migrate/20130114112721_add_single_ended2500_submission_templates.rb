class AddSingleEnded2500SubmissionTemplates < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      each_template do |settings|
        SubmissionTemplate.create!(Hiseq2500Helper.template(settings))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_template do |settings|
        SubmissionTemplate.find_by_name(settings[:name]).destroy
      end
    end
  end

  def self.each_template
    [
      {
        :name=>"Illumina-A - Cherrypick for pulldown - Pulldown ISC - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_a_pulldown_isc'],
        :cherrypick=>'cherrypick_for_illumina',
        :pipeline=>'a', :ended => 'single', :sub_params=>:sc
      },
      {
        :name=>"Illumina-A - Cherrypick for pulldown - Pulldown SC - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_a_pulldown_sc'],
        :cherrypick=>'cherrypick_for_illumina',
        :pipeline=>'a', :ended => 'single', :sub_params=>:sc
      },
      {
        :name=>"Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_a_pulldown_wgs'],
        :cherrypick=>'cherrypick_for_illumina',
        :pipeline=>'a', :ended => 'single', :sub_params=>:wgs
      },
      {
        :name=>"Illumina-A - Pulldown ISC - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_a_pulldown_isc'],
        :cherrypick=>false,
        :pipeline=>'a', :ended => 'single', :sub_params=>:sc},
      {
        :name=>"Illumina-A - Pulldown SC - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_a_pulldown_sc'],
        :cherrypick=>false,
        :pipeline=>'a', :ended => 'single', :sub_params=>:sc},
      {
        :name=>"Illumina-A - Pulldown WGS - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_a_pulldown_wgs'],
        :cherrypick=>false,
        :pipeline=>'a', :ended => 'single', :sub_params=>:wgs
      },
      {
        :name=>"Illumina-B - Cherrypicked - Multiplexed WGS - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_b_std'],
        :cherrypick=>'cherrypick_for_illumina_b',
        :pipeline=>'b', :ended => 'single', :sub_params=>:ill_b_single
      },
      {
        :name=>"Illumina-B - Multiplexed WGS - HiSeq 2500 Single end sequencing",
        :library_creation=>['illumina_b_std'],
        :cherrypick=>false,
        :pipeline=>'b', :ended => 'single', :sub_params=>:ill_b_single
      },
      {
        :name => "Illumina-C - Library creation - HiSeq 2500 Single end sequencing",
        :library_creation => ['illumina_c_library_creation','library_creation'],
        :cherrypick=> false,
        :pipeline=>'c', :ended => 'single', :sub_params=>:ill_c_single
      },
      {
        :name => "Illumina-C - Multiplexed library creation - HiSeq 2500 Single end sequencing",
        :library_creation => ['illumina_c_multiplexed_library_creation'],
        :cherrypick=> false,
        :pipeline=>'c', :ended => 'single', :sub_params=>:ill_c_single
      }
    ].each do |settings|
      yield settings
    end
  end

end
