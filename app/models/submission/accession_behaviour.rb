module Submission::AccessionBehaviour
  def self.included(base)
    base.class_eval do
      validate :check_data_release_and_accession_for_submission#, :if => :left_building_state?
    end
  end

  def check_data_release_and_accession_for_submission
    return if configatron.disable_accession_check == true

    if not study.valid_data_release_properties?
      errors.add_to_base('Please fill in the study data release information')
    elsif not study.ena_accession_required?
      # Nothing to do here because the study does not require ENA accessioning
    elsif not study.accession_number?
      errors.add_to_base('Study and all samples must have accession numbers')
    elsif not all_samples_have_accession_numbers?
      errors.add_to_base('Study and all samples must have accession numbers')
    end
  end

  def all_samples_have_accession_numbers?
    AssetGroup.new(:assets => self.assets).all_samples_have_accession_numbers?
  end
  private :all_samples_have_accession_numbers?
end
