class SampleTube < Tube
  include Api::SampleTubeIO::Extensions
  include ModelExtensions::SampleTube
  include StandardNamedScopes

  # In theory these two callbacks should ensure that if a 2D barcode is set then the barcode of
  # the SampleTube is properly configured, otherwise it will be set to the ID of the SampleTube
  # after it has been created.  Note that the after_create callback causes a second save of the
  # SampleTube instance, which should not fail ... in theory.
  before_validation do |record|
    unless record.two_dimensional_barcode.blank?
      two_d_barcode         = record.two_dimensional_barcode
      reduced_2d_barcode    = two_d_barcode.delete(two_d_barcode[0..1]).to_i
      record.barcode        = reduced_2d_barcode.to_s
      record.barcode_prefix = BarcodePrefix.find_by_prefix("SI")
    end
  end
  after_create do |record|
    record.barcode = record.id.to_s                     if record.two_dimensional_barcode.blank? and record.barcode.blank?
    record.name    = record.primary_aliquot.sample.name if record.name.blank? and not record.primary_aliquot.try(:sample).nil?

    record.save! if record.barcode_changed? or record.name_changed?
  end

  # All instances are labelled 'SampleTube', unless otherwise specified
  before_validation do |record|
    record.label = 'SampleTube' if record.label.blank?
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
