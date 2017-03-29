# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'lab_where_client'

class Plate < Asset
  include Api::PlateIO::Extensions
  include ModelExtensions::Plate
  include LocationAssociation::Locatable
  include Transfer::Associations
  include Transfer::State::PlateState
  include PlatePurpose::Associations
  include Barcode::Barcodeable
  include Asset::Ownership::Owned
  include Plate::FluidigmBehaviour
  include SubmissionPool::Association::Plate
  include PlateCreation::CreationChild

  extend QcFile::Associations
  has_qc_files

  # Contained associations all look up through wells (Wells in turn delegate to aliquots)
  has_many :contained_samples, through: :wells, source: :samples
  has_many :conatined_aliquots, through: :wells, source: :aliquots

  # We also look up studies and projects through wells
  has_many :studies, ->() { uniq }, through: :wells
  has_many :projects, ->() { uniq }, through: :wells

  has_many :well_requests_as_target, through: :wells, source: :requests_as_target
  has_many :orders_as_target, ->() { uniq }, through: :well_requests_as_target, source: :order

  # We use stock well associations here as stock_wells is already used to generate some kind of hash.
  has_many :stock_requests, ->() { uniq }, through: :stock_well_associations, source: :requests
  has_many :stock_well_associations, ->() { uniq }, through: :wells, source: :stock_wells
  has_many :stock_orders, ->() { uniq }, through: :stock_requests, source: :order
  has_many :extraction_attributes, foreign_key: 'target_id'

  has_many :siblings, through: :parents, source: :children

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

  # Transfer requests into a plate are the requests leading into the wells of said plate.
  has_many :transfer_requests, through: :wells, source: :transfer_requests_as_target
  has_many :transfer_requests_as_source, through: :wells

  scope :include_for_show, ->() {
    includes(
      requests: :request_metadata,
      wells: [
        :map_id,
        { aliquots: [:samples, :tag, :tag2] }
      ]
    )
  }

  # About 10x faster than going through the wells
  def submission_ids
    @siat ||= container_associations
              .joins('LEFT JOIN requests ON requests.target_asset_id = container_associations.content_id')
              .where.not(requests: { submission_id: nil }).where.not(requests: { state: Request::Statemachine::INACTIVE })
              .uniq.pluck(:submission_id)
  end

  def submission_ids_as_source
    @sias ||= container_associations
              .joins('LEFT JOIN requests ON requests.asset_id = container_associations.content_id')
              .where(['requests.submission_id IS NOT NULL AND requests.state NOT IN (?)', Request::Statemachine::INACTIVE])
              .uniq.pluck(:submission_id)
  end

  def all_submission_ids
    submission_ids_as_source.present? ?
      submission_ids_as_source :
      submission_ids
  end

  def self.derived_classes
    [self, *descendants].map(&:name)
  end

  def prefix
    barcode_prefix.try(:prefix) || self.class.prefix
  end

  def submissions
    s = Submission.select('submissions.*',).uniq
                  .joins([
                    'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
                    'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.asset_id'
                  ])
                  .where(['caplp.container_id = ?', id])
    return s unless s.blank?
    Submission.select('submissions.*',).uniq
              .joins([
                'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
                'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.target_asset_id'
              ])
              .where(['caplp.container_id = ?', id])
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

  class CommentsProxy
    attr_reader :plate

    def initialize(plate)
      @plate = plate
    end

    def comment_assn
      @asn ||= Comment.for_plate(plate)
    end

    def method_missing(method, *args)
      comment_assn.send(method, *args)
    end

    ##
    # We add the comments to each submission to ensure that are available for all the requests.
    # At time of writing, submissions add comments to each request, so there are a lot of comments
    # getting created here. (The intent is to change this so requests are treated similarly to plates)
    def create!(options)
      plate.submissions.each { |s| s.add_comment(options[:description], options[:user]) }
      Comment.create!(options.merge(commentable: plate))
    end

    def create(options)
      plate.submissions.each { |s| s.add_comment(options[:description], options[:user]) }
      Comment.create(options.merge(commentable: plate))
    end

    # By default rails treats sizes for grouped queries different to sizes
    # for ungrouped queries. Unfortunately plates could end up performing either.
    # Grouped return a hash, for which we want the length
    # otherwise we get an integer
    # We need to urgently revisit this, as this solution is horrible.
    # Adding to the horrible: The :all passed in to the super is to address a
    # rails bug with count and custom selects.
    def size(*args)
      s = super
      return s.length if s.respond_to?(:length)
      s
    end

    def count(*_args)
      s = super(:all)
      return s.length if s.respond_to?(:length)
      s
    end
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
  deprecate study: 'Caution plates may belong to multiple studies.'

  has_many :container_associations, foreign_key: :container_id, inverse_of: :plate
  has_many :wells, through: :container_associations, inverse_of: :plate do
    def attach(records)
      ActiveRecord::Base.transaction do
        proxy_association.owner.wells << records
      end
    end
    deprecate attach: 'Legacy method pre-jruby just use standard rails plate.wells << other_wells' # Legacy pre-jruby method to handle bulk import

    def construct!
      Map.where_plate_size(proxy_association.owner.size).where_plate_shape(proxy_association.owner.asset_shape).in_row_major_order.map do |location|
        build(map: location)
      end.tap do |wells|
        proxy_association.owner.save!
        AssetLink::Job.create(proxy_association.owner, wells)
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
  end

  scope :include_wells_and_attributes, -> { includes(wells: [:map, :well_attribute]) }

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
      select('assets.*').uniq
                        .joins([
                          'LEFT OUTER JOIN container_associations AS wscas ON wscas.container_id = assets.id',
                          'LEFT JOIN assets AS wswells ON wswells.id = content_id',
                          'LEFT JOIN aliquots AS wsaliquots ON wsaliquots.receptacle_id = wswells.id'
                        ])
                        .where(['wsaliquots.sample_id IN(?)', Array(sample)])
  }

 scope :with_requests, ->(requests) {
   select('assets.*').uniq
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
      .uniq
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

  def wells_sorted_by_map_id
    wells.sorted
  end

  def children_and_holded
    (children | wells)
  end

  def maps
    Map.where_plate_size(size).where_plate_shape(asset_shape)
  end

  def find_map_by_rowcol(row, col)
    # Count from 0
    description = asset_shape.location_from_row_and_column(row, col + 1, size)
    Map.find_by(
      description: description,
      asset_size: size,
      asset_shape_id: asset_shape
)
  end

  def find_well_by_rowcol(row, col)
    map = find_map_by_rowcol(row, col)
    return nil if map.nil?
    find_well_by_name(map.description)
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
    wells.located_at_position(well_name).first
  end
  alias :find_well_by_map_description :find_well_by_name

  def plate_header
    [''] + plate_columns
  end

  def plate_rows
    ('A'..((?A.getbyte(0) + height - 1).chr).to_s).to_a
  end

  def plate_columns
    (1..width).to_a
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
    (get_plate_type == 'Stock Plate' || get_plate_type.blank?) ? PlatePurpose.cherrypickable_as_source.first.name : get_plate_type
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
        storage_location = Location.find(params[:asset][:location_id])
        plate.location = storage_location
        plate.save!
      end
    rescue
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

  def create_plate_submission(project, study, user, _current_time)
    LinearSubmission.build!(
      study: study,
      project: project,
      workflow: genotyping_submission_workflow,
      user: user,
      assets: wells,
      request_types: submission_workflow_request_type_ids(genotyping_submission_workflow)
    )
  end

  def submission_workflow_request_type_ids(submission_workflow)
    submission_workflow.request_types.map(&:id)
  end

  def genotyping_submission_workflow
    Submission::Workflow.find_by(key: 'microarray_genotyping')
  end

  def self.create_plates_submission(project, study, plates, user)
    return false if user.nil? || project.nil? || study.nil?
    current_time = Time.now

    project.save
    plates.each do |plate|
      plate.generate_plate_submission(project, study, user, current_time)
    end

    true
  end

  # Should return true if any samples on the plate contains gender information
  def contains_gendered_samples?
    contained_samples.with_gender.any?
  end

  def generate_plate_submission(project, study, user, current_time)
    submission = create_plate_submission(project, study, user, current_time)
    if submission
      events.create!(message: I18n.t('studies.submissions.plate.event.success', barcode: barcode, submission_id: submission.id), created_by: user.login)
    else
      events.create!(message: I18n.t('studies.submissions.plate.event.failed', barcode: barcode), created_by: user.login)
      study.errors.add('plate_barcode', "Couldnt create submission for plate #{plate_barcode}")
    end
  end

  def create_sample_tubes
    wells.map(&:create_child_sample_tube)
  end

  def create_sample_tubes_and_print_barcodes(barcode_printer, location = nil)
    sample_tubes = create_sample_tubes
    print_job = LabelPrinter::PrintJob.new(barcode_printer.name,
                                          LabelPrinter::Label::PlateToTubes,
                                          sample_tubes: sample_tubes)
    print_job.execute
    if location
      location.set_locations(sample_tubes)
    end

    sample_tubes
  end

  def self.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, location, study)
    return nil if plates.empty?
    plate_barcodes = plates.map { |plate| plate.barcode }
    asset_group = AssetGroup.find_or_create_asset_group("#{plate_barcodes.join('-')} #{Time.now.to_formatted_s(:sortable)} ", study)
    plates.each do |plate|
      next if plate.wells.empty?
      asset_group.assets << plate.create_sample_tubes_and_print_barcodes(barcode_printer, location)
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

  def lookup_stock_plate
    spp = PlatePurpose.considered_stock_plate.pluck(:id)
    ancestors.order('created_at DESC').find_by(plate_purpose_id: spp)
  end
  private :lookup_stock_plate

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

  def child_dilution_plates_filtered_by_type(parent_model)
    children.select { |p| p.is_a?(parent_model) }
  end

  def children_of_dilution_plates(parent_model, child_model)
    child_dilution_plates_filtered_by_type(parent_model).map { |dilution_plate| dilution_plate.children.select { |p| p.is_a?(child_model) } }.flatten.select { |p| !p.nil? }
  end

  def child_pico_assay_plates
    children_of_dilution_plates(PicoDilutionPlate, PicoAssayAPlate)
  end

  def child_gel_dilution_plates
    children_of_dilution_plates(WorkingDilutionPlate, GelDilutionPlate)
  end

  def child_sequenom_qc_plates
    children_of_dilution_plates(WorkingDilutionPlate, SequenomQcPlate)
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

  def self.plates_from_scanned_plate_barcodes(source_plate_barcodes)
    source_plate_barcodes.scan(/\d+/).map { |barcode| find_from_machine_barcode(barcode) }
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
    unique_positions_on_plate, unique_positions_from_caller = Map.where_description(positions).where_plate_size(size).where_plate_shape(asset_shape).all.map(&:description).sort.uniq, positions.sort.uniq
    unique_positions_on_plate == unique_positions_from_caller
  end

  def name_for_label
    name
  end

  def set_plate_name_and_size
    self.name = "Plate #{barcode}" if name.blank?
    self.size = default_plate_size if size.nil?
    self.location = Location.find_by(name: 'Sample logistics freezer') if location_id.nil?
  end
  private :set_plate_name_and_size

  extend Metadata
  has_metadata do
    attribute(:infinium_barcode)
    attribute(:fluidigm_barcode)
  end

  def barcode_label_for_printing
    PrintBarcode::Label.new(
      number: barcode,
      study: find_study_abbreviation_from_parent,
      suffix: parent.try(:barcode),
      prefix: barcode_prefix.prefix
    )
  end

  def height
    asset_shape.plate_height(size)
  end

  def width
    asset_shape.plate_width(size)
  end

  # This method returns a map from the wells on the plate to their stock well.
  def stock_wells
    # Optimisation: if the plate is a stock plate then it's wells are it's stock wells!
    return Hash[wells.with_pool_id.map { |w| [w, [w]] }] if stock_plate?
    Hash[wells.include_stock_wells.with_pool_id.map { |w| [w, w.stock_wells.sort_by { |sw| sw.map.column_order }] }.reject { |_, v| v.empty? }].tap do |stock_wells_hash|
      raise "No stock plate associated with #{id}" if stock_wells_hash.empty?
    end
  end

  def convert_to(new_purpose)
    update_attributes!(plate_purpose: new_purpose)
  end

  def compatible_purposes
    PlatePurpose.compatible_with_purpose(purpose)
  end

  def update_qc_values_with_parser(parser)
    ActiveRecord::Base.transaction do
      well_hash = Hash[wells.include_map.includes(:well_attribute).map { |w| [w.map_description, w] }]

      parser.each_well_and_parameters do |position, well_updates|
        # We might have a nil well if a plate was only partially cherrypicked
        well = well_hash[position]
        next if well.nil?
        well.update_qc_values_with_hash(well_updates)
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

  # Barcode is stored as a string, jet in a number of places is treated as
  # a number. If we conver it before searching, things are faster!
  def find_by_barcode(barcode)
    super(barcode.to_s)
  end

  alias_method :friendly_name, :sanger_human_barcode
  def subject_type
    'plate'
  end
end
