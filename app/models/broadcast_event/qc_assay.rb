# frozen_string_literal: true

require_dependency 'qc_assay'

# Serializes lab events for the event warehouse
class BroadcastEvent::QcAssay < BroadcastEvent
  seed_class ::QcAssay

  def self.generate_events(qc_assay)
    # A qc_assay is made up of multiple qc_results, which usually have the same assay_type, don't HAVE to.
    # We generate an event per assay type, and distinguish between then with properties
    qc_assay
      .qc_results
      .distinct
      .pluck(:assay_type, :assay_version)
      .map { |assay_type, assay_version| create!(seed: qc_assay, properties: { assay_type:, assay_version: }) }
  end

  has_subjects(:sample) { |_qc_assay, event| event.samples }
  has_subjects(:study) { |_qc_assay, event| event.studies }
  has_subjects(:assayed_labware) { |_qc_assay, event| event.assayed_labware }
  has_subjects(:stock_plate) { |_qc_assay, event| event.stock_plates }

  has_metadata(:lot_number, :lot_number)
  has_metadata(:assay_version) { |_qc_assay, event| event.assay_version }

  def event_type
    "quant_#{assay_type.downcase.gsub(/[^\w]+/, '_')}"
  end

  def assay_type
    properties.fetch(:assay_type, template_result.assay_type)
  end

  def assay_version
    properties.fetch(:assay_version, template_result.assay_version)
  end

  def template_result
    seed.qc_results.first
  end

  def qc_results
    @qc_results || seed.qc_results.where(properties).includes(%i[asset samples studies])
  end

  def samples
    qc_results.flat_map(&:samples).uniq
  end

  def studies
    qc_results.flat_map(&:studies).uniq
  end

  def assayed_labware
    qc_results.flat_map { |qcr| qcr.asset.labware }.uniq
  end

  def stock_plates
    assayed_labware.flat_map(&:original_stock_plates).compact.uniq
  end
end
