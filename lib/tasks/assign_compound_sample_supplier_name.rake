# frozen_string_literal: true
namespace :compound_sample do
  desc 'Set the supplier_name on compound samples if all component samples share the same supplier_name'
  task set_consistent_supplier_name_for_compound_samples: :environment do
    grouped_by_compound_sample_id = SampleCompoundComponent.select(:compound_sample_id, :component_sample_id)
      .group_by(&:compound_sample_id)

    grouped_by_compound_sample_id.each do |compound_sample_id, compound_component_array|
      compound_sample_metadata = compound_sample_metadata_to_set_supplier_name(compound_sample_id)
      next if compound_sample_metadata.nil?

      supplier_name = consistent_supplier_name(compound_component_array)
      next if supplier_name.nil?

      compound_sample_metadata.update(supplier_name:)

      puts "Set sample #{compound_sample_id} supplier_name to: #{supplier_name}"
    end
  end

  # Returns the compound sample metadata only if it is present and has no supplier_name yet.
  #
  # @param compound_sample_id [Integer] The sample ID of the compound sample
  # @return [Sample::Metadata, nil] The metadata record to update or nil if not applicable
  def compound_sample_metadata_to_set_supplier_name(compound_sample_id)
    compound_sample_metadata = Sample::Metadata.where(sample_id: compound_sample_id)
    return nil if compound_sample_metadata.empty? || compound_sample_metadata.first.supplier_name.present?

    compound_sample_metadata.first
  end

  # Checks if all component samples linked to the compound sample share the same supplier_name.
  #
  # @param component_links [Array<SampleCompoundComponent>] The components for the compound sample
  # @return [String, nil] The consistent supplier_name if found; nil otherwise
  def consistent_supplier_name(compound_component_samples)
    supplier_names = []
    compound_component_samples.each do |compound_component_sample|
      sample_metadata = Sample::Metadata.where(sample_id: compound_component_sample.component_sample_id)
      supplier_names.push(sample_metadata.first.supplier_name)
    end
    supplier_names.uniq.size == 1 ? supplier_names.first : nil
  end
end
