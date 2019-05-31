require 'linefeed_fix'
require 'csv'
module SampleManifest::InputBehaviour
  def self.included(base)
    base.class_eval do
      include ManifestUtil
      # Ensure that we can override previous manifest information when required
      extend ValidationStateGuard
      validation_guard(:override_previous_manifest)

      # Ensure that we can update the samples of a manifest
      has_many :samples
      accepts_nested_attributes_for :samples
      alias_method(:update_without_sample_manifest!, :update!)
      alias_method(:update!, :update_with_sample_manifest!)
    end
  end

  def update_with_sample_manifest!(attributes, user = nil)
    ActiveRecord::Base.transaction do
      ensure_samples_are_being_updated_by_manifest(attributes, user)
      update_without_sample_manifest!(attributes.with_indifferent_access)
    end
  end

  # updates the manifest barcode list e.g. after applying a foreign barcode
  def update_barcodes
    self.barcodes = labware.map(&:human_barcode)
    save!
  end

  private

  def ensure_samples_are_being_updated_by_manifest(attributes, user)
    attributes.fetch(:samples_attributes, []).each do |sample_attributes|
      sample_attributes.merge!(
        updating_from_manifest: true,
        can_rename_sample: true,
        user_performing_manifest_update: user,
        override_previous_manifest: (override_previous_manifest? || attributes[:override_previous_manifest])
      )
      sample_attributes[:sample_metadata_attributes].delete_if { |_, v| v.nil? }
      sample_attributes[:sample_metadata_attributes][:updating_from_manifest] = true
    end
  end
end
