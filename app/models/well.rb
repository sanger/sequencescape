# frozen_string_literal: true
# A Well is a {Receptacle} on a {Plate}, it can contain one or more {Aliquot aliquots}.
# A plate may have multiple wells, with the two most common sizes being 12*8 (96) and
# 24*26 (384). The wells are differentiated via their {Map} which corresponds to a
# row and column. Most well locations are identified by a letter-number combination,
# eg. A1, H12.
class Well < Receptacle # rubocop:todo Metrics/ClassLength
  include Api::WellIo::Extensions
  include ModelExtensions::Well
  include Cherrypick::VolumeByNanoGrams
  include Cherrypick::VolumeByNanoGramsPerMicroLitre
  include Cherrypick::VolumeByMicroLitre
  include StudyReport::WellDetails
  include Tag::Associations
  include Api::Messages::FluidigmPlateIo::WellExtensions
  include Api::Messages::QcResultIo::WellExtensions

  class Link < ApplicationRecord
    # Caution! We are using delete_all and import to manage well links.
    # Any callbacks you add here will not be called in those circumstances.
    self.table_name = 'well_links'
    self.inheritance_column = nil

    belongs_to :target_well, class_name: 'Well'
    belongs_to :source_well, class_name: 'Well'

    scope :stock, -> { where(type: 'stock') }
  end

  self.stock_message_template = 'WellStockResourceIo'
  self.per_page = 500

  has_many :stock_well_links, -> { stock }, class_name: 'Well::Link', foreign_key: :target_well_id
  has_many :stock_wells, through: :stock_well_links, source: :source_well do
    def attach!(wells)
      Well::Link.import(attach(wells))
    end

    def attach(wells)
      proxy_association.owner.stock_well_links.build(wells.map { |well| { type: 'stock', source_well: well } })
    end
  end
  has_many :customer_requests, class_name: 'CustomerRequest', foreign_key: :asset_id
  has_many :outer_requests, through: :stock_wells, source: :customer_requests
  has_many :qc_metrics, inverse_of: :asset, foreign_key: :asset_id
  has_many :qc_reports, through: :qc_metrics
  has_many :reported_criteria, through: :qc_reports, source: :product_criteria
  has_many :target_well_links, -> { stock }, class_name: 'Well::Link', foreign_key: :source_well_id
  has_many :target_wells, through: :target_well_links, source: :target_well

  # Can have many key value pairs of metadata
  has_many :poly_metadata, as: :metadatable, dependent: :destroy

  # Returns a collection of PolyMetadatum records associated with the Well.
  # This method overrides the autogenerated poly_metadata method to pick the
  # correct metadatable_type instead of the parent type. Without this override,
  # the generated SQL uses the wrong class name, e.g. Receptacle instead of Well.
  #
  # @return [ActiveRecord::Relation] a collection of PolyMetadatum records
  def poly_metadata
    PolyMetadatum.where(metadatable_id: id, metadatable_type: self.class.name)
  end

  belongs_to :plate, foreign_key: :labware_id
  has_one :well_attribute, inverse_of: :well

  accepts_nested_attributes_for :well_attribute

  before_create :well_attribute # Ensure all wells have attributes

  scope :with_concentration, -> { joins(:well_attribute).where('well_attributes.concentration IS NOT NULL') }
  scope :include_stock_wells, -> { includes(stock_wells: :requests_as_source) }
  scope :include_stock_wells_for_modification,
        -> do
          # Preload rather than include, as otherwise joins result
          # in exponential expansion of the number of records loaded
          # and you run out of memory.
          preload(
            :stock_well_links,
            stock_wells: {
              requests_as_source: [
                :target_asset,
                :request_type,
                :request_metadata,
                :request_events,
                { initial_project: :project_metadata, submission: :orders }
              ]
            }
          )
        end

  scope :on_plate_purpose, ->(purposes) { joins(:labware).where(labware: { plate_purpose_id: purposes }) }

  # added version of scope with includes to avoid multiple calls to LabWhere in qc report when getting storage location
  # for wells in the same plate
  scope :on_plate_purpose_included,
        ->(purposes) do
          includes(labware: :barcodes).references(:labware).where(labware: { plate_purpose_id: purposes })
        end

  scope :for_study_through_aliquot, ->(study) { joins(:aliquots).where(aliquots: { study_id: study }) }

  scope :with_report,
        ->(product_criteria) do
          joins(:reported_criteria).where(
            product_criteria: {
              product_id: product_criteria.product_id,
              stage: product_criteria.stage
            }
          )
        end

  scope :without_report, ->(product_criteria) { where.not(id: with_report(product_criteria)) }

  scope :stock_wells_for,
        ->(wells) { joins(:target_well_links).where(well_links: { target_well_id: [wells].flatten.map(&:id) }) }
  scope :target_wells_for,
        ->(wells) do
          select_table
            .select('well_links.source_well_id AS stock_well_id')
            .joins(:stock_well_links)
            .where(well_links: { source_well_id: wells })
        end

  scope :pooled_as_target_by_transfer,
        -> do
          joins("LEFT JOIN transfer_requests patb ON #{table_name}.id=patb.target_asset_id")
            .select_table
            .select('patb.submission_id AS pool_id')
            .distinct
        end

  scope :pooled_as_source_by,
        ->(type) do
          joins("LEFT JOIN requests pasb ON #{table_name}.id=pasb.asset_id")
            .where(
              [
                '(pasb.sti_type IS NULL OR pasb.sti_type IN (?)) AND pasb.state IN (?)',
                [type, *type.descendants].map(&:name),
                Request::Statemachine::OPENED_STATE
              ]
            )
            .select_table
            .select('pasb.submission_id AS pool_id')
            .distinct
        end

  # It feels like we should be able to do this with just includes and order, but oddly this causes more disruption
  # downstream
  scope :in_column_major_order, -> { joins(:map).order('column_order ASC').select_table.select('column_order') }
  scope :in_row_major_order, -> { joins(:map).order('row_order ASC').select_table.select('row_order') }
  scope :in_inverse_column_major_order,
        -> { joins(:map).order('column_order DESC').select_table.select('column_order') }
  scope :in_inverse_row_major_order, -> { joins(:map).order('row_order DESC').select_table.select('row_order') }
  scope :in_plate_column,
        ->(col, size) do
          joins(:map).where(maps: { description: Map::Coordinate.descriptions_for_column(col, size), asset_size: size })
        end
  scope :in_plate_row,
        ->(row, size) do
          joins(:map).where(maps: { description: Map::Coordinate.descriptions_for_row(row, size), asset_size: size })
        end
  scope :with_blank_samples,
        -> do
          joins(
            [
              'INNER JOIN aliquots ON aliquots.receptacle_id=assets.id',
              'INNER JOIN samples ON aliquots.sample_id=samples.id'
            ]
          ).where(['samples.empty_supplier_sample_name=?', true])
        end
  scope :without_blank_samples, -> { joins(aliquots: :sample).where(samples: { empty_supplier_sample_name: false }) }

  delegate :location, :location_id, :location_id=, :printable_target, :source_plate, to: :plate, allow_nil: true
  delegate :column_order, :row_order, to: :map, allow_nil: true

  class << self
    def delegate_to_well_attribute(attribute, options = {})
      class_eval <<-END_OF_METHOD_DEFINITION
        def get_#{attribute}
          self.well_attribute.#{attribute} || #{options[:default].inspect}
        end
      END_OF_METHOD_DEFINITION
    end

    def writer_for_well_attribute_as_float(attribute)
      class_eval <<-END_OF_METHOD_DEFINITION
        def set_#{attribute}(value)
          self.well_attribute.update!(:#{attribute} => value.to_f)
        end
      END_OF_METHOD_DEFINITION
    end

    def hash_stock_with_targets(wells, purpose_names)
      return {} unless purpose_names

      purposes = PlatePurpose.where(name: purpose_names)

      # We might need to be careful about this line in future.
      target_wells = Well.target_wells_for(wells).on_plate_purpose(purposes).preload(:well_attribute).with_concentration

      target_wells.group_by(&:stock_well_id)
    end
  end

  def stock_wells_for_downstream_wells
    labware&.stock_plate? ? [self] : stock_wells
  end

  def subject_type
    'well'
  end

  def outer_request(submission_id)
    outer_requests.order(id: :desc).find_by(submission_id:)
  end

  def qc_results_by_key
    @qc_results_by_key ||= qc_results.by_key
  end

  def qc_result_for(key)
    results = qc_results_by_key[key]
    result = results.first.value if results.present?

    return if result.nil?
    return result.to_f.round(3) if result.to_s.include?('.')

    result.to_i
  end

  def generate_name(_)
    # Do nothing
  end

  def external_identifier
    display_name
  end

  def well_attribute
    super || build_well_attribute
  end

  delegate :measured_volume, :measured_volume=, to: :well_attribute
  delegate_to_well_attribute(:pico_pass)
  delegate_to_well_attribute(:sequenom_count)
  delegate_to_well_attribute(:gel_pass)
  delegate_to_well_attribute(:study_id)
  delegate_to_well_attribute(:gender)
  delegate_to_well_attribute(:rin)
  writer_for_well_attribute_as_float(:rin)

  delegate_to_well_attribute(:concentration)
  writer_for_well_attribute_as_float(:concentration)

  delegate_to_well_attribute(:molarity)
  writer_for_well_attribute_as_float(:molarity)

  delegate_to_well_attribute(:current_volume)
  alias get_volume get_current_volume
  writer_for_well_attribute_as_float(:current_volume)

  def update_volume(volume_change)
    value_current_volume = get_current_volume.nil? ? 0 : get_current_volume
    set_current_volume([0, value_current_volume + volume_change].max)
  end
  alias set_volume set_current_volume
  delegate_to_well_attribute(:initial_volume)
  writer_for_well_attribute_as_float(:initial_volume)

  delegate_to_well_attribute(:buffer_volume, default: 0.0)
  writer_for_well_attribute_as_float(:buffer_volume)

  delegate_to_well_attribute(:requested_volume)
  writer_for_well_attribute_as_float(:requested_volume)

  delegate_to_well_attribute(:picked_volume)
  writer_for_well_attribute_as_float(:picked_volume)

  delegate_to_well_attribute(:robot_minimum_picking_volume)
  writer_for_well_attribute_as_float(:robot_minimum_picking_volume)

  delegate_to_well_attribute(:gender_markers)

  # rubocop:todo Metrics/MethodLength
  def update_gender_markers!(gender_markers, resource) # rubocop:todo Metrics/AbcSize
    if well_attribute.gender_markers == gender_markers
      gender_marker_event = events.where(family: 'update_gender_markers').order('id desc').first
      if gender_marker_event.blank?
        events.update_gender_markers!(resource)
      elsif resource == 'SNP' && gender_marker_event.content != resource
        events.update_gender_markers!(resource)
      end
    else
      events.update_gender_markers!(resource)
    end

    well_attribute.update!(gender_markers:)
  end

  # rubocop:enable Metrics/MethodLength

  def update_sequenom_count!(sequenom_count, resource)
    events.update_sequenom_count!(resource) unless well_attribute.sequenom_count == sequenom_count
    well_attribute.update!(sequenom_count:)
  end

  # The sequenom pass value is either the string 'Unknown' or it is the combination of gender marker values.
  def get_sequenom_pass
    markers = well_attribute.gender_markers
    markers.is_a?(Array) ? markers.join : markers
  end

  # Returns the name of the position (eg. A1) of the well
  def absolute_position_name
    map_description
  end

  def qc_data
    { pico: get_pico_pass, gel: get_gel_pass, sequenom: get_sequenom_pass, concentration: get_concentration }
  end

  def buffer_required?
    get_buffer_volume > 0.0
  end

  #
  # Returns a name for the well in the format HumanBarcode:Location eg. DN12345S:A1
  # @note Be *very* wary of changing this as we have places in limber
  #       (https://github.com/sanger/limber/blob/develop/app/helpers/exports_helper.rb)
  #       where it is assumed to contain the barcode and well location. It is highly likely
  #       that we aren't the only ones making this assumption.
  def display_name
    source = association_cached?(:plate) ? plate : labware
    plate_name = source.present? ? source.human_barcode : '(not on a plate)'
    plate_name ||= source.display_name # In the even the plate is barcodeless (ie strip tubes) use its name
    "#{plate_name}:#{map_description}"
  end

  def details
    return 'Not yet picked' if plate.nil?

    plate.purpose.try(:name) || 'Unknown plate purpose'
  end

  def latest_stock_metrics(product)
    # If we don't have any stock wells, use ourself. If it is a stock well, we'll find our
    # qc metric. If its not a stock well, then a metric won't be present anyway
    metric_wells = stock_wells.empty? ? [self] : stock_wells
    metric_wells.filter_map { |stock_well| stock_well.qc_metrics.for_product(product).most_recent_first.first }.uniq
  end

  def asset_type_for_request_types
    self.class
  end

  def update_from_qc(qc_result)
    Well::AttributeUpdater.update(self, qc_result)
  end

  def name
    nil
  end

  def library_name
    nil
  end
end
