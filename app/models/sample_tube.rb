#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2014 Genome Research Ltd.
class SampleTube < Tube
  include Api::SampleTubeIO::Extensions
  include ModelExtensions::SampleTube
  include StandardNamedScopes

  after_create do |record|
    record.barcode = AssetBarcode.new_barcode           if record.barcode.blank?
    record.name    = record.primary_aliquot.sample.name if record.name.blank? and not record.primary_aliquot.try(:sample).nil?

    record.save! if record.barcode_changed? or record.name_changed?
  end

  # All instances are labelled 'SampleTube', unless otherwise specified
  before_validation do |record|
    record.label = 'SampleTube' if record.label.blank?
  end

  def created_with_request_options
    {}
  end

  def move_asset_group(study_from, asset_group)
    asset_groups_study_from = self.asset_groups.find_all_by_study_id(study_from.id)
    self.asset_groups = self.asset_groups - asset_groups_study_from
    self.asset_groups << asset_group
    asset_group.save
    self.save
  end

  def move_study_sample(study_from, study_to, current_user)
    aliquots.all(:include => :sample).each do |aliquot|
      study_samples = aliquot.sample.study_samples.find_all_by_study_id(study_from.id)
      if study_samples.empty?
        study_to.study_samples.create!(:sample => aliquot.sample)
      else
        study_samples.each do |study_sample|
          study_sample.update_attributes!(:study => study_to)
        end
      end
    end

    study_from.events.create(
      :message => "Asset #{self.id} was moved to Study #{study_to.id}",
      :created_by => current_user.login,
      :content => "Asset moved by #{current_user.login}",
      :of_interest_to => "administrators"
    )

    study_to.events.create(
      :message => "Asset #{self.id} was moved from Study #{study_from.id}",
      :created_by => current_user.login,
      :content => "Asset moved by #{current_user.login}",
      :of_interest_to => "administrators"
    )
  end

  def can_be_created?
    true
  end

end
