module Submission::AccessionBehaviour
  def self.included(base)
    base.class_eval do
      validate :check_data_release_and_accession_for_submission, :if => :can_check_data_release_and_accession?
    end
  end

  def can_check_data_release_and_accession?
    self.study.present? && self.request_types_require_accessioning?
  end

  def request_types_require_accessioning?
    RequestType.find(self.request_types).detect(&:accessioning_required?)
  end

  def check_data_release_and_accession_for_submission
    return if configatron.disable_accession_check == true

    if not study.valid_data_release_properties?
      errors.add(:study,"#{study.name}: Please fill in the study data release information")
    elsif not study.ena_accession_required?
      # Nothing to do here because the study does not require ENA accessioning
    elsif not study.accession_number?
      errors.add(:study,"#{study.name} and all samples must have accession numbers")
    elsif not all_samples_have_accession_numbers?
      errors.add_to_base("Samples #{unaccessioned_samples} are missing accession numbers")
    end
  end

  private

  def asset_group
    AssetGroup.new(:assets => self.assets)
  end

  def unaccessioned_samples
    asset_group.unaccessioned_samples.map(&:name).to_sentence
  end

  def all_samples_have_accession_numbers?
    asset_group.all_samples_have_accession_numbers?
  end
end
