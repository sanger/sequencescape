# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'lab_where_client'

class Plate < Asset
  include Api::PlateIO::Extensions
  include ModelExtensions::Plate
  include Transfer::Associations
  include Transfer::State::PlateState
  # include PlatePurpose::Associations
  include Barcode::Barcodeable
  include Asset::Ownership::Owned
  include Plate::FluidigmBehaviour
  include SubmissionPool::Association::Plate
  include PlateCreation::CreationChild

  extend QcFile::Associations
  has_qc_files

  belongs_to :plate_purpose, foreign_key: :plate_purpose_id
  belongs_to :purpose, foreign_key: :plate_purpose_id

  has_many :container_associations, foreign_key: :container_id, inverse_of: :plate
  has_many :wells, through: :container_associations, inverse_of: :plate do
    def attach(records)
      ActiveRecord::Base.transaction do
        proxy_association.owner.wells << records
      end
    end
    deprecate attach: 'Legacy method pre-jruby just use standard rails plate.wells << other_wells' # Legacy pre-jruby method to handle bulk import

    # Build empty wells for the plate.
    def construct!
      proxy_association.owner.maps.in_row_major_order.pluck(:id).map do |location_id|
        Well.create!(map_id: location_id)
      end.tap do |wells|
        ContainerAssociation.import(wells.map { |w| { content_id: w.id, container_id: proxy_association.owner.id } })
        # If the well association has already been loaded, reload it. Otherwise rails will continue
        # to think the plate has no wells.
        proxy_association.reload if proxy_association.loaded?
      end
    end

    def map_from_locations
      {}.tap do |location_to_well|
        walk_in_column_major_order do |well, _|
          raise "Duplicated well at #{well.map.description}" if location_to_well.key?(well.map)
          location_to_well[well.map] = well
        end
      end
    end

    # Returns the wells with their pool identifier included
    def with_pool_id
      proxy_association.owner.plate_purpose.pool_wells(self)
    end

    # Yields each pool and the wells that are in it
    def walk_in_pools(&block)
      with_pool_id.group_by(&:pool_id).each(&block)
    end

    # Walks the wells A1, B1, C1, ... A2, B2, C2, ... H12
    def walk_in_column_major_order
      in_column_major_order.each { |well| yield(well, well.map.column_order) }
    end

    # Walks the wells A1, A2, ... B1, B2, ... H12
    def walk_in_row_major_order
      in_row_major_order.each { |well| yield(well, well.map.row_order) }
    end

    def in_preferred_order
      proxy_association.owner.plate_purpose.in_preferred_order(self)
    end

    def indexed_by_location
      @index_well_cache ||= index_by(&:map_description)
    end
  end

  # Contained associations all look up through wells (Wells in turn delegate to aliquots)
  has_many :contained_samples, through: :wells, source: :samples
  has_many :conatined_aliquots, through: :wells, source: :aliquots

  # We also look up studies and projects through wells
  has_many :studies, ->() { distinct }, through: :wells
  has_many :projects, ->() { distinct }, through: :wells
  has_many :well_requests_as_target, through: :wells, source: :requests_as_target
  has_many :well_requests_as_source, through: :wells, source: :requests_as_source
  has_many :orders_as_target, ->() { distinct }, through: :well_requests_as_target, source: :order
  # We use stock well associations here as stock_wells is already used to generate some kind of hash.
  has_many :stock_requests, ->() { distinct }, through: :stock_well_associations, source: :requests
  has_many :stock_well_associations, ->() { distinct }, through: :wells, source: :stock_wells
  has_many :stock_orders, ->() { distinct }, through: :stock_requests, source: :order
  has_many :extraction_attributes, foreign_key: 'target_id'
  has_many :siblings, through: :parents, source: :children
  # Transfer requests into a plate are the requests leading into the wells of said plate.
  has_many :transfer_requests, through: :wells, source: :transfer_requests_as_target
  has_many :transfer_requests_as_source, through: :wells
  has_many :transfer_requests_as_target, through: :wells
  has_many :transfer_request_collections, ->() { distinct }, through: :transfer_requests_as_source

  # The default state for a plate comes from the plate purpose
  delegate :default_state, to: :plate_purpose, allow_nil: true
  def state
    plate_purpose.state_of(self)
  end

  def update_volume(volume_change)
    ActiveRecord::Base.transaction do
      wells.each do |w|
        w.update_volume(volume_change)
      end
    end
  end

  def occupied_well_count
    wells.with_contents.count
  end

  def summary_hash
    {
      asset_id: id,
      barcode: { ean13_barcode: ean13_barcode, human_readable: sanger_human_barcode },
      occupied_wells: wells.with_aliquots.include_map.map(&:map_description)
    }
  end

  def cherrypick_completed
    plate_purpose.cherrypick_completed(self)
  end

  def source_plate
    purpose && purpose.source_plate(self)
  end

  SAMPLE_PARTIAL = 'assets/samples_partials/plate_samples'

  # The type of the barcode is delegated to the plate purpose because that governs the number of wells
  delegate :barcode_type, to: :plate_purpose, allow_nil: true
  delegate :asset_shape, to: :plate_purpose, allow_nil: true
  delegate :supports_multiple_submissions?, to: :plate_purpose
  delegate :fluidigm_barcode, to: :plate_metadata
  delegate :dilution_factor, :dilution_factor=, to: :plate_metadata

  validates_length_of :fluidigm_barcode, is: 10, allow_blank: true

  scope :include_for_show, ->() {
    includes(
      requests: :request_metadata,
      wells: [
        :map_id,
        { aliquots: %i(samples tag tag2) }
      ]
    )
  }
  scope :with_plate_purpose, ->(*purposes) { where(plate_purpose_id: purposes.flatten) }

  # Submissions on requests out of the plate
  # May not have been started yet
  has_many :waiting_submissions, -> { distinct }, through: :well_requests_as_source, source: :submission
  # The requests which were being processed to make the plate
  has_many :in_progress_submissions, -> { distinct }, through: :transfer_requests_as_target, source: :submission

  def submission_ids
    @siat ||= in_progress_submissions.pluck(:submission_id)
  end

  def submission_ids_as_source
    @sias ||= waiting_submissions.pluck(:submission_id)
  end

  # Prioritised the submissions that have been made from the plate
  # then falls back onto the ones under which the plate was made
  def all_submission_ids
    submission_ids_as_source.presence || submission_ids
  end

  def submissions
    waiting_submissions.presence || in_progress_submissions
  end

  def prefix
    barcode_prefix.try(:prefix) || self.class.prefix
  end

  def barcode_dilution_factor_created_at_hash
    return {} if barcode.blank?
    {
      barcode: generate_machine_barcode,
      dilution_factor: dilution_factor.to_s,
      created_at: created_at
    }
  end

  def iteration
    iter = siblings # assets sharing the same parent
           .where(plate_purpose_id: plate_purpose_id, sti_type: sti_type) # of the same purpose and type
           .where('assets.created_at <= ?', created_at) # created before or at the same time
           .count('assets.id') # count the siblings.

    iter.zero? ? nil : iter # Maintains compatibility with legacy version
  end

  # Delegate the change of state to our plate purpose.
  def transition_to(state, user, contents = nil, customer_accepts_responsibility = false)
    purpose.transition_to(self, state, user, contents, customer_accepts_responsibility)
  end

  def comments
    @comments ||= CommentsProxy.new(self)
  end

  def priority
    Submission.joins([
      'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
      'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.asset_id'
    ])
              .where(['caplp.container_id = ?', id]).maximum('submissions.priority') ||
      Submission.joins([
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.target_asset_id'
      ])
                .where(['caplp.container_id = ?', id]).maximum('submissions.priority') ||
      0
  end

  # Plates can easily belong to multiple studies, so this method is just misleading.
  def study
    wells.first.try(:study)
  end
  deprecate study: 'Plates can belong to multiple studies, use #studies instead.'

  scope :include_wells_and_attributes, -> { includes(wells: %i(map well_attribute)) }

  # has_many :wells, :as => :holder, :class_name => "Well"
  DEFAULT_SIZE = 96
  self.prefix = 'DN'

  self.per_page = 50

  before_create :set_plate_name_and_size

  scope :qc_started_plates, -> {
    select('DISTINCT assets.*')
      .joins('LEFT OUTER JOIN `events` ON events.eventful_id = assets.id LEFT OUTER JOIN `asset_audits` ON asset_audits.asset_id = assets.id')
      .where(["(events.family = 'create_dilution_plate_purpose' OR asset_audits.key = 'slf_receive_plates') AND plate_purpose_id = ?", PlatePurpose.stock_plate_purpose.id])
      .order('assets.id DESC')
      .includes(:events, :asset_audits)
  }

  # TODO: Make these more railsy
  scope :with_sample, ->(sample) {
    select('assets.*').distinct
                      .joins([
                        'LEFT OUTER JOIN container_associations AS wscas ON wscas.container_id = assets.id',
                        'LEFT JOIN assets AS wswells ON wswells.id = content_id',
                        'LEFT JOIN aliquots AS wsaliquots ON wsaliquots.receptacle_id = wswells.id'
                      ])
                      .where(['wsaliquots.sample_id IN(?)', Array(sample)])
  }

  scope :with_requests, ->(requests) {
                          select('assets.*').distinct
                                            .joins([
                                              'INNER JOIN container_associations AS wrca ON wrca.container_id = assets.id',
                                              'INNER JOIN requests AS wrr ON wrr.asset_id = wrca.content_id'
                                            ]).where([
                                              'wrr.id IN (?)',
                                              requests.map(&:id)
                                            ])
                        }

  scope :output_by_batch, ->(batch) {
    joins(wells: { requests_as_target: :batch })
      .where(batches: { id: batch })
  }

  scope :include_wells, -> { includes(:wells) } do
    def to_include
      [:wells]
    end

    def with(subinclude)
      scoped(include: { wells: subinclude })
    end
  end

  scope :with_wells, ->(wells) {
    select('DISTINCT assets.*')
      .joins(:container_associations)
      .where(container_associations: { content_id: wells.map(&:id) })
  }
  #->() {where(:assets=>{:sti_type=>[Plate,*Plate.descendants].map(&:name)})},
  has_many :descendant_plates, class_name: 'Plate', through: :links_as_ancestor, foreign_key: :ancestor_id, source: :descendant
  has_many :descendant_lanes,  class_name: 'Lane', through: :links_as_ancestor, foreign_key: :ancestor_id, source: :descendant
  has_many :tag_layouts

  scope :with_descendants_owned_by, ->(user) {
    joins(descendant_plates: :plate_owner)
      .where(plate_owners: { user_id: user })
      .distinct
  }

  scope :source_plates, -> {
    joins(:plate_purpose)
      .where('plate_purposes.id = plate_purposes.source_purpose_id')
  }

  scope :with_wells_and_requests, ->() {
    eager_load(wells: [
      :uuid_object, :map,
      {
        requests_as_target: [
          { initial_study: :uuid_object },
          { initial_project: :uuid_object },
          { asset: { aliquots: :sample } }
        ]
      }
    ])
  }

  def maps
    Map.where_plate_size(size).where_plate_shape(asset_shape)
  end

  def find_map_by_rowcol(row, col)
    # Count from 0
    maps.find_by(description: map_description(row, col))
  end

  def map_description(row, col)
    asset_shape.location_from_row_and_column(row, col + 1, size)
  end

  def find_well_by_rowcol(row, col)
    map_description = map_description(row, col)
    return nil if map_description.nil?
    find_well_by_name(map_description)
  end

  def add_well_holder(well)
    children << well
    wells << well
  end

  def add_well(well, row = nil, col = nil)
    add_well_holder(well)
    if row
      well.map = find_map_by_rowcol(row, col)
    end
  end

  def add_well_by_map_description(well, map_description)
    add_well_holder(well)
    well.map = Map.find_by(description: map_description, asset_size: size)
    well.save!
  end

  def add_and_save_well(well, row = nil, col = nil)
    add_well(well, row, col)
    well.save!
  end

  def find_well_by_name(well_name)
    if wells.loaded?
      wells.indexed_by_location[well_name]
    else
      wells.located_at_position(well_name).first
    end
  end
  alias :find_well_by_map_description :find_well_by_name

  def plate_rows
    ('A'..((?A.getbyte(0) + height - 1).chr).to_s).to_a
  end

  def plate_columns
    (1..width)
  end

  def get_plate_type
    if descriptor_value('Plate Type').nil?
      plate_type = get_external_value('plate_type_description')
      set_plate_type(plate_type)
    end
    descriptor_value('Plate Type')
  end

  def set_plate_type(result)
    add_descriptor(Descriptor.new(name: 'Plate Type', value: result))
    save
  end

  def stock_plate_name
    (get_plate_type == 'Stock Plate' || get_plate_type.blank?) ? PlateType.first.name : get_plate_type
  end

  def details
    purpose.try(:name) || 'Unknown plate purpose'
  end

  def control_well_exists?
    Request.into_by_id(wells.map(&:id)).any? do |request|
      request.asset.plate.is_a?(ControlPlate)
    end
  end

  # A plate has a sample with the specified name if any of its wells have that sample.
  def sample?(sample_name)
    wells.any? do |well|
      well.aliquots.any? { |aliquot| aliquot.sample.name == sample_name }
    end
  end

  def storage_location
    @storage_location ||= obtain_storage_location
  end

  def storage_location_service
    @storage_location_service
  end

  def barcode_for_tecan
    raise StandardError, 'Purpose is not valid' if plate_purpose.present? and not plate_purpose.valid?
    plate_purpose.present? ? send(:"#{plate_purpose.barcode_for_tecan}") : ean13_barcode
  end

  delegate :infinium_barcode, to: :plate_metadata

  def infinium_barcode=(barcode)
    plate_metadata.infinium_barcode = barcode
    plate_metadata.save!
  end

  def valid_infinium_barcode?(_barcode)
    true
  end

  def self.create_from_rack_csv(file_location, plate_barcode)
    plate = create(name: "Plate #{plate_barcode}", barcode: plate_barcode, size: 96)

    CSV.foreach(file_location) do |row|
      map = Map.find_for_cell_location(row.first, plate.size)
      if row.last.strip.blank?
        well = plate.wells.create(map_id: map.id)
      else
        asset = Asset.find_by(two_dimensional_barcode: row.last.strip)
        if asset.nil?
          well = plate.wells.create(map_id: map.id)
        else
          well = plate.wells.create(sample: asset.sample, map_id: map.id)
          well.name = "#{asset} #{well.id}"
          well.save
          AssetLink.create_edge(asset, well)
        end
      end
    end
    plate
  end

  def submission_time(current_time)
    current_time.strftime('%Y-%m-%dT%H_%M_%SZ')
  end

  def self.create_plates_with_barcodes(params)
    begin
      params[:snp_plates].each do |_index, plate_barcode_id|
        next if plate_barcode_id.blank?
        plate = Plate.create(barcode: plate_barcode_id.to_s, name: "Plate #{plate_barcode_id}", size: DEFAULT_SIZE)
        plate.save!
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
    true
  end

  def self.plate_ids_from_requests(requests)
    plate_ids = []
    requests.map do |request|
      next if request.asset.nil?
      next unless request.asset.is_a?(Well)
      next if request.asset.plate.nil?
      plate_ids << request.asset.plate.id
    end

    plate_ids.uniq
  end

  def plate_asset_group_name(current_time)
    if barcode
      barcode + "_asset_group_#{submission_time(current_time)}"
    else
      id + "_asset_group_#{submission_time(current_time)}"
    end
  end

  # Should return true if any samples on the plate contains gender information
  def contains_gendered_samples?
    contained_samples.with_gender.any?
  end

  def create_sample_tubes
    wells.map(&:create_child_sample_tube)
  end

  def create_sample_tubes_and_print_barcodes(barcode_printer)
    sample_tubes = create_sample_tubes
    print_job = LabelPrinter::PrintJob.new(barcode_printer.name,
                                           LabelPrinter::Label::PlateToTubes,
                                           sample_tubes: sample_tubes)
    print_job.execute

    sample_tubes
  end

  def self.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, study)
    return nil if plates.empty?
    plate_barcodes = plates.map { |plate| plate.barcode }
    asset_group = AssetGroup.find_or_create_asset_group("#{plate_barcodes.join('-')} #{Time.now.to_formatted_s(:sortable)} ", study)
    plates.each do |plate|
      next if plate.wells.empty?
      asset_group.assets << plate.create_sample_tubes_and_print_barcodes(barcode_printer)
    end

    return nil if asset_group.assets.empty?
    asset_group.save!

    asset_group
  end

  def stock_plate?
    return true if plate_purpose.nil?
    plate_purpose.stock_plate? && plate_purpose.attatched?(self)
  end

  def stock_plate
    @stock_plate ||= stock_plate? ? self : lookup_stock_plate
  end

  def original_stock_plates
    ancestors.where(plate_purpose_id: PlatePurpose.stock_plate_purpose)
  end

  def ancestor_of_purpose(ancestor_purpose_id)
    return self if plate_purpose_id == ancestor_purpose_id
    ancestors.order(created_at: :desc).find_by(plate_purpose_id: ancestor_purpose_id)
  end

  def ancestors_of_purpose(ancestor_purpose_id)
    return [self] if plate_purpose_id == ancestor_purpose_id
    ancestors.order(created_at: :desc).where(plate_purpose_id: ancestor_purpose_id)
  end

  def find_study_abbreviation_from_parent
    parent.try(:wells).try(:first).try(:study).try(:abbreviation)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes[:barcode]
    # If this gets called on plate_purpose.plates it implicitly scopes
    # plate to the plate purpose of choice.
    barcode    = nil if barcode.present? and unscoped.find_by(barcode: barcode).present?
    barcode  ||= PlateBarcode.create.barcode
    create!(attributes.merge(barcode: barcode), &block)
  end

  #--
  # NOTE: I'm getting odd behaviour where '&method(:find_from_machine_barcode)' raises a SecurityError.  I haven't
  # been able to track down why, and it only happens under 'rake cucumber', so somewhere something is doing something
  # nasty.
  #++
  def self.plates_from_scanned_plates_and_typed_plate_ids(source_plate_barcodes)
    scanned_plates = source_plate_barcodes.scan(/\d+/).map { |v| find_from_machine_barcode(v) }
    typed_plates   = source_plate_barcodes.scan(/\d+/).map { |v| find_by(barcode: v) }

    (scanned_plates | typed_plates).compact
  end

  def number_of_blank_samples
    wells.with_blank_samples.count
  end

  def default_plate_size
    DEFAULT_SIZE
  end

  def scored?
    wells.any? { |w| w.get_gel_pass }
  end

  def buffer_required?
    wells.any?(&:buffer_required?)
  end

  def valid_positions?(positions)
    unique_positions_from_caller = positions.sort.uniq
    unique_positions_on_plate = maps.where_description(unique_positions_from_caller)
                                    .distinct
                                    .pluck(:description).sort
    unique_positions_on_plate == unique_positions_from_caller
  end

  def name_for_label
    name
  end

  extend Metadata
  has_metadata do
    custom_attribute(:infinium_barcode)
    custom_attribute(:fluidigm_barcode)
  end

  def height
    asset_shape.plate_height(size)
  end

  def width
    asset_shape.plate_width(size)
  end

  # This method returns a map from the wells on the plate to their stock well.
  def stock_wells
    # Optimisation: if the plate is a stock plate then it's wells are it's stock wells!]
    if stock_plate?
      wells.with_pool_id.each_with_object({}) { |w, store| store[w] = [w] }
    else
      wells.include_stock_wells.with_pool_id.each_with_object({}) do |w, store|
        storted_stock_wells = w.stock_wells.sort_by { |sw| sw.map.column_order }
        store[w] = storted_stock_wells unless storted_stock_wells.empty?
      end.tap do |stock_wells_hash|
        raise "No stock plate associated with #{id}" if stock_wells_hash.empty?
      end
    end
  end

  def convert_to(new_purpose)
    update_attributes!(plate_purpose: new_purpose)
  end

  def compatible_purposes
    PlatePurpose.compatible_with_purpose(purpose)
  end

  def well_hash
    @well_hash ||= wells.include_map.includes(:well_attribute).index_by(&:map_description)
  end

  def update_qc_values_with_parser(parser, scale: nil)
    ActiveRecord::Base.transaction do
      parser.each_well_and_parameters do |position, well_updates|
        # We might have a nil well if a plate was only partially cherrypicked
        well = well_hash[position]
        scale ||= well_updates.keys.map { |k| [k, 1] }
        next if well.nil?
        well.update_qc_values_with_hash(well_updates, scale)
        well.save!
      end
    end
    true
  end

  def samples_in_order(order_id)
    Sample.for_plate_and_order(id, order_id)
  end

  def samples_in_order_by_target(order_id)
    Sample.for_plate_and_order_as_target(id, order_id)
  end

  def team
    ProductLine.joins([
      'INNER JOIN request_types ON request_types.product_line_id = product_lines.id',
      'INNER JOIN requests ON requests.request_type_id = request_types.id',
      'INNER JOIN well_links ON well_links.source_well_id = requests.asset_id AND well_links.type = "stock"',
      'INNER JOIN container_associations AS ca ON ca.content_id = well_links.target_well_id'
    ]).find_by(['ca.container_id = ?', id]).try(:name) || 'UNKNOWN'
  end

  # Barcode is stored as a string, yet in a number of places is treated as
  # a number. If we convert it before searching, things are faster!
  def find_by_barcode(barcode)
    super(barcode.to_s)
  end

  alias_method :friendly_name, :sanger_human_barcode
  def subject_type
    'plate'
  end

  private

  def obtain_storage_location
    # From LabWhere
    info_from_labwhere = LabWhereClient::Labware.find_by_barcode(ean13_barcode) # rubocop:disable Rails/DynamicFindBy
    unless info_from_labwhere.nil? || info_from_labwhere.location.nil?
      @storage_location_service = 'LabWhere'
      return info_from_labwhere.location.location_info
    end

    # From ETS
    @storage_location_service = 'ETS'
    return 'Control' if is_a?(ControlPlate)
    return '' if barcode.blank?
    return %w(storage_area storage_device building_area building).map do |key|
      get_external_value(key)
    end.compact.join(' - ')
  rescue LabWhereClient::LabwhereException => e
    @storage_location_service = 'None'
    return "Not found (#{e.message})"
  end

  def lookup_stock_plate
    spp = PlatePurpose.considered_stock_plate.pluck(:id)
    ancestors.order('created_at DESC').find_by(plate_purpose_id: spp)
  end

  def set_plate_name_and_size
    self.name = "Plate #{barcode}" if name.blank?
    self.size = default_plate_size if size.nil?
  end
end
