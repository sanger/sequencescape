#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Well < Aliquot::Receptacle
  include Api::WellIO::Extensions
  include ModelExtensions::Well
  include Cherrypick::VolumeByNanoGrams
  include Cherrypick::VolumeByNanoGramsPerMicroLitre
  include Cherrypick::VolumeByMicroLitre
  include StudyReport::WellDetails
  include Tag::Associations
  include AssetRack::WellAssociations::AssetRackAssociation
  include Api::Messages::FluidigmPlateIO::WellExtensions

  class Link < ActiveRecord::Base
    self.table_name = 'well_links'
    self.inheritance_column = nil

    belongs_to :target_well, :class_name => 'Well'
    belongs_to :source_well, :class_name => 'Well'
  end
  has_many :stock_well_links,  ->() { where(type:'stock') }, :class_name => 'Well::Link', :foreign_key => :target_well_id

  has_many :stock_wells, :through => :stock_well_links, :source => :source_well do
    def attach!(wells)
      attach(wells).tap do |_|
        proxy_association.owner.save!
      end
    end
    def attach(wells)
      proxy_association.owner.stock_well_links.build(wells.map { |well| { :type => 'stock', :source_well => well } })
    end
  end

  has_many :qc_metrics, :inverse_of => :asset, :foreign_key => :asset_id

  # hams_many due to eager loading requirement and can't have a has one through a has_many
  has_many :latest_child_well, ->() { limit(1).order('asset_links.descendant_id DESC').where(:assets=>{:sti_type => 'Well'}) }, :class_name => 'Well', :through => :links_as_parent, :source => :descendant

  scope :include_stock_wells, -> { includes(:stock_wells => :requests_as_source) }
  scope :include_map,         -> { includes(:map) }

  scope :located_at, ->(location) {
    joins(:map).where(:maps => { :description => location })
  }

  scope :on_plate_purpose, ->(purposes) {
      joins(:plate).
      where(:plates_assets=>{:plate_purpose_id=>purposes})
  }

  scope :for_study_through_sample, ->(study) {
      joins(:aliquots=>{:sample=>:study_samples}).
      where(:study_samples=>{:study_id=>study})
  }

  scope :for_study_through_aliquot, ->(study) {
      joins(:aliquots).
      where(:aliquots=>{:study_id=>study})
  }

  #
  scope :without_report, ->(product_criteria) {
    joins([
      'LEFT OUTER JOIN qc_metrics AS wr_qcm ON wr_qcm.asset_id = assets.id',
      'LEFT OUTER JOIN qc_reports AS wr_qcr ON wr_qcr.id = wr_qcm.qc_report_id',
      'LEFT OUTER JOIN product_criteria AS wr_pc ON wr_pc.id = wr_qcr.product_criteria_id'
    ]).
    group('assets.id').
    having("NOT BIT_OR(wr_pc.product_id = ? AND wr_pc.stage = ?)",product_criteria.product_id,product_criteria.stage)
  }

  has_many :target_well_links,  ->() { where(sti_type:'stock') }, :class_name => 'Well::Link', :foreign_key => :source_well_id
  has_many :target_wells, :through => :target_well_links, :source => :target_well

  scope :stock_wells_for, ->(wells) {
    joins(:target_well_links).
    where(:well_links =>{:target_well_id => [wells].flatten.map(&:id) })
  }

  scope :located_at_position, ->(position) { joins(:map).readonly(false).where(:maps => { :description => position }) }

  contained_by :plate

  # We don't handle this in contained by as identifiable pieces of labware
  # may still be contained. (Such as if we implement tube racks)
  def labware
    plate
  end

  delegate :location, :location_id, :location_id=, :printable_target, :to => :container , :allow_nil => true
  self.per_page = 500

  has_one :well_attribute, :inverse_of => :well
  before_create { |w| w.create_well_attribute unless w.well_attribute.present? }

  scope :pooled_as_target_by, ->(type) {
    joins('LEFT JOIN requests patb ON assets.id=patb.target_asset_id').
    where([ '(patb.sti_type IS NULL OR patb.sti_type IN (?))', [ type, *type.descendants ].map(&:name) ]).
    select('assets.*, patb.submission_id AS pool_id').uniq
  }
  scope :pooled_as_source_by, ->(type) {
    joins('LEFT JOIN requests pasb ON assets.id=pasb.asset_id').
    where([ '(pasb.sti_type IS NULL OR pasb.sti_type IN (?)) AND pasb.state IN (?)', [ type, *type.descendants ].map(&:name), Request::Statemachine::OPENED_STATE  ]).
    select('assets.*, pasb.submission_id AS pool_id').uniq
  }

  # It feels like we should be able to do this with just includes and order, but oddly this causes more disruption downstream
  scope :in_column_major_order,         -> { joins(:map).order('column_order ASC').select('assets.*, column_order') }
  scope :in_row_major_order,            -> { joins(:map).order('row_order ASC').select('assets.*, row_order') }
  scope :in_inverse_column_major_order, -> { joins(:map).order('column_order DESC').select('assets.*, column_order') }
  scope :in_inverse_row_major_order,    -> { joins(:map).order('row_order DESC').select('assets.*, row_order') }

  scope :in_plate_column, ->(col,size) {  joins(:map).where(:maps => {:description => Map::Coordinate.descriptions_for_column(col,size), :asset_size => size }) }
  scope :in_plate_row,    ->(row,size) {  joins(:map).where(:maps => {:description => Map::Coordinate.descriptions_for_row(row,size), :asset_size =>size }) }

  scope :with_blank_samples, -> {
    joins([
      "INNER JOIN aliquots ON aliquots.receptacle_id=assets.id",
      "INNER JOIN samples ON aliquots.sample_id=samples.id"
    ]).
    where(['samples.empty_supplier_sample_name=?',true])
  }

  scope :without_blank_samples, ->() {
    joins(:aliquots=>:sample).
    where(:samples => { :empty_supplier_sample_name=> false })
  }

  scope :with_contents, -> {
    joins('INNER JOIN aliquots ON aliquots.receptacle_id=assets.id')
  }

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
          self.well_attribute.update_attributes!(:#{attribute} => value.to_f)
        end
      END_OF_METHOD_DEFINITION
    end
  end

  def generate_name(_)
    # Do nothing
  end

  def external_identifier
    display_name
  end

  #hotfix
  def well_attribute_with_creation
    self.well_attribute_without_creation || self.build_well_attribute
  end
  alias_method_chain(:well_attribute, :creation)

  delegate_to_well_attribute(:pico_pass)
  delegate_to_well_attribute(:sequenom_count)
  delegate_to_well_attribute(:gel_pass)
  delegate_to_well_attribute(:study_id)
  delegate_to_well_attribute(:gender)

  delegate_to_well_attribute(:concentration)
  alias_method(:get_pico_result, :get_concentration)
  writer_for_well_attribute_as_float(:concentration)

  delegate_to_well_attribute(:molarity)
  writer_for_well_attribute_as_float(:molarity)

  delegate_to_well_attribute(:current_volume)
  alias_method(:get_volume, :get_current_volume)
  writer_for_well_attribute_as_float(:current_volume)

  delegate_to_well_attribute(:buffer_volume, :default => 0.0)
  writer_for_well_attribute_as_float(:buffer_volume)

  delegate_to_well_attribute(:requested_volume)
  writer_for_well_attribute_as_float(:requested_volume)

  delegate_to_well_attribute(:picked_volume)
  writer_for_well_attribute_as_float(:picked_volume)

  delegate_to_well_attribute(:gender_markers)

  def update_gender_markers!(gender_markers, resource)
    if self.well_attribute.gender_markers == gender_markers
      gender_marker_event = self.events.where(family:'update_gender_markers').order('id desc').first
      if gender_marker_event.blank?
        self.events.update_gender_markers!(resource)
      elsif resource == 'SNP'  && gender_marker_event.content != resource
        self.events.update_gender_markers!(resource)
      end
    else
      self.events.update_gender_markers!(resource)
    end

    self.well_attribute.update_attributes!(:gender_markers => gender_markers)
  end

  def update_sequenom_count!(sequenom_count, resource)
    unless self.well_attribute.sequenom_count == sequenom_count
      self.events.update_sequenom_count!(resource)
    end
    self.well_attribute.update_attributes!(:sequenom_count => sequenom_count)

  end

  # The sequenom pass value is either the string 'Unknown' or it is the combination of gender marker values.
  def get_sequenom_pass
    markers = self.well_attribute.gender_markers
    markers.is_a?(Array) ? markers.join : markers
  end

  def map_description
    return read_attribute("map_description") if read_attribute("map_description").present?
    return nil if map.nil?
    return nil unless map.description.is_a?(String)

    map.description
  end

  def valid_well_on_plate
    return false unless self.is_a?(Well)
    well_plate = plate
    return false unless well_plate.is_a?(Plate)
    return false if well_plate.barcode.blank?
    return false if map_id.nil?
    return false unless map.description.is_a?(String)

    true
  end

  def create_child_sample_tube
    Tube::Purpose.standard_sample_tube.create!(:map => self.map, :aliquots => aliquots.map(&:dup)).tap do |sample_tube|
      AssetLink.create_edge(self, sample_tube)
    end
  end

  def qc_data
    {:pico          => self.get_pico_pass,
     :gel           => self.get_gel_pass,
     :sequenom      => self.get_sequenom_pass,
     :concentration => self.get_concentration }
  end

  def buffer_required?
    get_buffer_volume > 0.0
  end
  private :buffer_required?

  # If we eager load, things fair badly, and we end up returning all children.
  def find_latest_child_well
    latest_child_well.sort_by(&:id).last
  end

  validate(:on => :save) do |record|
    record.errors.add(:name, "cannot be specified for a well") unless record.name.blank?
  end

  def display_name
    plate_name = self.plate.present? ? self.plate.sanger_human_barcode : '(not on a plate)'
    plate_name ||= plate.display_name # In the even the plate is barcodeless (ie strip tubes) use its name
    "#{plate_name}:#{map ? map.description : ''}"
  end

  def details
    return 'Not yet picked' if plate.nil?
    plate.purpose.try(:name)||'Unknown plate purpose'
  end

  def can_be_created?
    plate.stock_plate?
  end

  def latest_stock_metric(product)
    raise StandardError, 'Too many stock wells to report metrics' if stock_wells.count > 1
    # If we don't have any stock wells, use ourself. If it is a stock well, we'll find our
    # qc metric. If its not a stock well, then a metric won't be present anyway
    stock_well = stock_wells.first || self
    stock_well.qc_metrics.for_product(product).most_recent_first.first
  end

  def source_plate
    plate.source_plate
  end
end
