# frozen_string_literal: true
# The record cache collects all ids used in the request and optimizes
# the lookup into a single query, with appropriate eager loading.
# Built for use with {Api::V2::PickListResource}
class PickList::RecordCache
  RECEPTACLE_KEYS = %i[source_receptacle_id study_id project_id].freeze
  LABWARE_KEYS = %i[source_labware_id source_labware_barcode study_id project_id].freeze

  # Pick-list cache where the source_receptacles are indicated directly via
  # source_receptacle_id:
  class ByReceptacle < PickList::RecordCache
    KEYS = %i[source_receptacle_id study_id project_id].freeze

    def convert(entry)
      source_receptacle_id, study_id, project_id = entry.values_at(:source_receptacle_id, :study_id, :project_id)
      entry
        .except(*RECEPTACLE_KEYS)
        .to_hash
        .merge(
          source_receptacle: source_receptacle(source_receptacle_id),
          study: study(study_id),
          project: project(project_id)
        )
    end

    def source_receptacle(id)
      @source_receptacle ||= Receptacle.includes(:studies, :projects).find(stored(:source_receptacle_id)).index_by(&:id)
      @source_receptacle[id] || missing_resource('receptacle ids', id)
    end
  end

  # Pick-list cache where the source_receptacles are indicated indirectly via
  # source_labware_id: or source_labware_barcode: A pick will be generated for
  # all aliquot containing receptacles in the labware
  class ByLabware < PickList::RecordCache
    KEYS = %i[source_labware_id source_labware_barcode study_id project_id].freeze

    def convert(entry)
      source_labware_id, source_labware_barcode = entry.values_at(:source_labware_id, :source_labware_barcode)
      source_receptacles = receptacles_for(source_labware_id, source_labware_barcode)
      study_id, project_id = entry.values_at(:study_id, :project_id)
      other_keys = entry.except(*LABWARE_KEYS).to_hash
      source_receptacles.map do |source_receptacle|
        other_keys.merge(source_receptacle: source_receptacle, study: study(study_id), project: project(project_id))
      end
    end

    def source_receptacle_by_labware_id(id)
      @source_receptacle_by_labware_id ||=
        Receptacle
          .preload(:studies, :projects)
          .with_contents
          .where(labware_id: stored(:source_labware_id))
          .group_by(&:labware_id)
      @source_receptacle_by_labware_id[id] || missing_resource('labware ids', id)
    end

    # This is a little complicated.
    # We can easily find receptacles by the labware barcode, but the problem is
    # the labware itself may have more than one barcode associated with it.
    # If we then group by barcode, which one do we use?
    # The select here adds a found_barcode attribute to the returned record,
    # which matches the barcode we originally looked up the well by.
    # As we're about to use the exact same barcode to pull the information back
    # out the cache, we're fine.
    def source_receptacle_by_labware_barcode(barcode)
      @source_receptacle_by_labware_barcode ||=
        Receptacle
          .preload(:studies, :projects)
          .with_contents
          .with_barcode(stored(:source_labware_barcode))
          .select_table
          .select('barcodes.barcode AS found_barcode')
          .group_by(&:found_barcode)
      @source_receptacle_by_labware_barcode[barcode] || missing_resource('labware barcodes', barcode)
    end

    def receptacles_for(source_labware_id, source_labware_barcode)
      if source_labware_barcode
        source_receptacle_by_labware_barcode(source_labware_barcode)
      elsif source_labware_id
        source_receptacle_by_labware_id(source_labware_id)
      else
        raise JSONAPI::Exceptions::BadRequest, 'No labware specified'
      end
    end
  end

  # Create a new cache
  # @param picks [Array<Hash>] An array of hashes describing picks.
  def initialize(picks)
    @store = Hash.new { |hash, key| hash[key] = Set.new }
    picks.each { |pick| add(pick) }
  end

  def add(entry)
    self.class::KEYS.each { |key| @store[key] << entry[key] }
  end

  private

  def stored(store)
    @store[store].delete(nil).to_a
  end

  def study(id)
    return nil unless id

    @study ||= Study.find(stored(:study_id)).index_by(&:id)
    @study[id] || missing_resource('study ids', id)
  end

  def project(id)
    return nil unless id

    @project ||= Project.find(stored(:project_id)).index_by(&:id)
    @project[id] || missing_resource('project ids', id)
  end

  def missing_resource(property, value)
    raise KeyError, "Could not find '#{value}' in #{property}"
  end
end
