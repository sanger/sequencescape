module SampleManifest::InputBehaviour::SampleUpdating
  module MetadataRules
    def self.included(base)
      base.class_eval do
        extend ValidationStateGuard
        validation_guard(:updating_from_manifest)

        # These need to be checked when updating from a sample manifest.  We need to be able to display
        # the sample ID so this can't be done with validates_presence_of
        validates :volume, :concentration, if: :updating_from_manifest?, presence: { message: proc { |object, _data| "can't be blank for #{object.sample.sanger_sample_id}" } }
      end
    end

    def accession_number_from_manifest=(new_value)
      self.sample_ebi_accession_number ||= new_value
      return new_value unless new_value.present? && new_value != sample_ebi_accession_number

      errors.add(:sample_ebi_accession_number, 'can not be changed')
      raise ActiveRecord::RecordInvalid, self
    end
  end

  def self.included(base)
    base.class_eval do
      extend ValidationStateGuard

      # You cannot create a sample through updating the sample manifest
      validates_each(:id, on: :create, if: :updating_from_manifest?) do |record, _attr, value|
        record.errors.add(:base, "Could not find sample #{record.sanger_sample_id}") if value.blank?
      end

      # We ensure that certain fields are updated properly if we're doing so through a manifest
      before_validation(if: :updating_from_manifest?) do |record|
        if record.sample_supplier_name_empty?(record.sample_metadata.supplier_name)
          record.reset_all_attributes_to_previous_values
          record.empty_supplier_sample_name = true
          record.generate_no_update_event
        else
          record.empty_supplier_sample_name = false
          record.updated_by_manifest        = true
        end
      end

      # If the sample has already been updated by a manifest, and we're not overriding it
      # then we should reset the sample information
      before_validation(if: :updating_from_manifest?) do |record|
        record.reset_all_attributes_to_previous_values unless record.can_override_previous_manifest?
      end

      # We need to record any updates if we're working through a manifest update
      attr_accessor :user_performing_manifest_update
      after_save(:handle_update_event, if: :updating_from_manifest?)

      # The validation guards need declaring last so that they are reset after all of the after_save
      # callbacks that may need them are executed.
      validation_guard(:updating_from_manifest)
      validation_guard(:override_previous_manifest)
    end

    # Modify the metadata so that it does the right checks when we are updating from a manifest
    base::Metadata.class_eval do
      include MetadataRules
    end
  end

  def handle_update_event(user = user_performing_manifest_update)
    events.updated_using_sample_manifest!(user) unless @generate_no_update_event
  end

  def generate_no_update_event
    @generate_no_update_event = true
  end

  def generate_no_update_event?
    @generate_no_update_event
  end

  def can_override_previous_manifest?
    # Have to use the previous value of 'updated_by_manifest' here as it may have been changed by
    # the current update.
    !updated_by_manifest_was || override_previous_manifest?
  end

  # Resets all of the attributes to their previous values
  def reset_all_attributes_to_previous_values
    reload unless new_record?
  end
end
