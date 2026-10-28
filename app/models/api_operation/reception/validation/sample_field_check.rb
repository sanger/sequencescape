# frozen_string_literal: true

# Checks the sample fields of the new labware's samples that name a record
# or depend on another field. Mirrors the sample manifest's specialised
# fields:
# - reference_genome names an existing reference genome (ReferenceGenome),
#   ignoring case. An unknown name is reported once, at the first sample
#   that uses it, with how many do; the names are looked up in one query.
# - A Bioscan control (BioscanControlType) has a supplier name beginning with
#   CONTROL_; a pcr positive or pcr negative control is not in H12; a lysate
#   negative control is in H12. The supplier name is the one the sample gets:
#   bioscan_supplier_name, which replaces supplier_sample_name, if given. A
#   tube has no wells, so a lysate negative control can't be in one.
#
# A rule the manifest doesn't have, as one of its columns can't contradict
# another: control_type and bioscan_control_type are the same when a sample
# gives both.
class ApiOperation::Reception::Validation::SampleFieldCheck <
      ApiOperation::Reception::Validation::Check
  # CONTROL_ at the start of the name, then at least one character that
  # isn't whitespace
  CONTROL_NAME = /\ACONTROL_\S+/

  # The Bioscan controls that can't be in CONTROL_WELL
  PCR_CONTROLS = ['pcr positive', 'pcr negative'].freeze

  # The Bioscan control that must be in CONTROL_WELL
  LYSATE_CONTROL = 'lysate negative'

  # The well kept for the lysate negative control
  CONTROL_WELL = 'H12'

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||=
      reference_genome_errors + control_type_errors + bioscan_control_errors
  end

  private

  def reference_genome_errors
    users = users_by_name('reference_genome')
    return [] if users.empty?

    known = ::ReferenceGenome.where(name: users.keys).pluck(:name)
      .to_set(&:downcase)
    users.filter_map do |name, name_users|
      next if known.include?(name.downcase)

      error("#{name_users.first.pointer}/reference_genome",
            "No reference genome named #{name} (#{used_by(name_users)})")
    end
  end

  # An error for each sample whose two control type fields differ
  def control_type_errors
    input.new_samples.filter_map do |sample|
      type, bioscan =
        sample.fields.values_at('control_type', 'bioscan_control_type')
      next unless type && bioscan && type != bioscan

      error("#{sample.pointer}/bioscan_control_type",
            "bioscan_control_type (#{bioscan}) differs from " \
            "control_type (#{type})")
    end
  end

  def bioscan_control_errors
    input.new_labware.flat_map(&:receptacles).flat_map do |receptacle|
      receptacle.samples.flat_map do |sample|
        next [] unless sample.fields.key?('bioscan_control_type')

        [supplier_name_error(sample),
         well_error(sample, receptacle.position)].compact
      end
    end
  end

  def supplier_name_error(sample)
    field, name =
      if sample.fields.key?('bioscan_supplier_name')
        ['bioscan_supplier_name', sample.fields['bioscan_supplier_name']]
      else
        ['supplier_sample_name', sample.supplier_sample_name]
      end
    return if CONTROL_NAME.match?(name)

    error("#{sample.pointer}/#{field}",
          'A control needs a supplier name beginning with CONTROL_')
  end

  def well_error(sample, position)
    control = sample.fields['bioscan_control_type']
    detail =
      if PCR_CONTROLS.include?(control) && position == CONTROL_WELL
        "A #{control} control can't be in #{CONTROL_WELL}"
      elsif control == LYSATE_CONTROL && position != CONTROL_WELL
        "A #{control} control must be in #{CONTROL_WELL}, " \
          "not #{position || 'in a tube'}"
      end
    error("#{sample.pointer}/bioscan_control_type", detail) if detail
  end
end
