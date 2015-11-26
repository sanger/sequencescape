#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
class Transfer::BetweenPlateAndTubes < Transfer
  DESTINATION_INCLUDES = {
    :destination => [
      :uuid_object, {
        :aliquots => [
          :uuid_object,
          :bait_library, {
            :tag => :tag_group,
            :sample => [
              :uuid_object, {
                :primary_study   => { :study_metadata => :reference_genome },
                :sample_metadata => :reference_genome
              }
            ]
          }
        ]
      }
    ]
  }

  class WellToTube < ActiveRecord::Base
    self.table_name =('well_to_tube_transfers')

    belongs_to :transfer, :class_name => 'Transfer::BetweenPlateAndTubes'
    validates_presence_of :transfer

    belongs_to :destination, :class_name => 'Tube'
    validates_presence_of :destination

    validates_presence_of :source

    scope :include_destination, -> { includes(Transfer::BetweenPlateAndTubes::DESTINATION_INCLUDES) }
  end

  include Transfer::ControlledDestinations

  # Records the transfers from the wells on the plate to the assets they have gone into.
  has_many :well_to_tubes, :class_name => 'Transfer::BetweenPlateAndTubes::WellToTube', :foreign_key => :transfer_id
  scope :include_transfers, -> { includes( :well_to_tubes => DESTINATION_INCLUDES ) }

  def transfers
    Hash[well_to_tubes.include_destination.map { |t| [t.source, tube_to_hash(t.destination)] }]
  end

  # NOTE: Performance enhancement to convert a tube to it's minimal representation for presentation.
  def tube_to_hash(tube)
    # Only build the hash once per tube. Shows significant speed improvement, esp. with label_text
    @tubes||={}
    @tubes[tube.id] ||= {
      :uuid    => tube.uuid,
      :name    => tube.name,
      :state   => tube.state,
      :label   => { :text => tube.purpose.name }
    }.tap do |details|
      barcode_to_hash(tube) { |s| details[:barcode] = s }
      barcode_to_hash(tube.stock_plate) { |s| details[:stock_plate] = { :barcode => s } }
      details[:label][:prefix] = tube.role unless tube.role.nil?
    end
  end
  private :tube_to_hash

  def barcode_to_hash(barcoded)
    yield({
      :number          => barcoded.barcode,
      :prefix          => barcoded.barcode_prefix.prefix,
      :two_dimensional => barcoded.two_dimensional_barcode,
      :ean13           => barcoded.ean13_barcode,
      :type            => barcoded.barcode_type
    }) if barcoded.present?
  end
  private :barcode_to_hash

  #--
  # The source plate wells need to be translated back to the stock plate wells, which simply
  # involves following the transfer requests back up until we hit the stock plate.  We only need
  # to follow one transfer request for each well as the submission related stock wells will be in
  # the same final well.  Once we get to the stock well we then find the request that has the
  # well as a source and the target is an MX library tube.
  #++
  def well_to_destination
    ActiveSupport::OrderedHash[
      source.stock_wells.map do |well, stock_wells|
        tube = locate_mx_library_tube_for(well, stock_wells)
        (tube.nil? or should_well_not_be_transferred?(well)) ? nil : [ well, [ tube, stock_wells ] ]
      end.compact
    ]
  end
  private :well_to_destination

  def record_transfer(source, destination, stock_well)
    @transfers ||= {}
    @transfers[source.map.description] = [ destination, stock_well ]
  end
  private :record_transfer

  after_create :build_well_to_tube_transfers
  def build_well_to_tube_transfers
    tube_to_stock_wells = Hash.new { |h,k| h[k] = [] }
    self.well_to_tubes.build(@transfers.map do |source, (destination, stock_wells)|
      tube_to_stock_wells[destination].concat(stock_wells)
      { :source => source, :destination => destination }
    end).map(&:save!)

    tube_to_stock_wells.each do |tube, stock_wells|
      tube.update_attributes!(:name => tube_name_for(stock_wells))
    end
  end
  private :build_well_to_tube_transfers

  # Builds the name for the tube based on the wells that are being transferred from by finding their stock plate wells and
  # creating an appropriate range.
  def tube_name_for(stock_wells)
    source_wells = source.plate_purpose.source_wells_for(stock_wells).sort {|w1,w2| w1.map.column_order <=> w2.map.column_order }
    stock_plates = source_wells.map(&:plate).uniq
    raise StandardError, "There appears to be no stock plate!" if stock_plates.empty?
    raise StandardError, "Cannot handle cross plate pooling!" if stock_plates.size > 1
    first,last = source_wells.first.map_description, source_wells.last.map_description
    "#{stock_plates.first.sanger_human_barcode} #{first}:#{last}"
  end
  private :tube_name_for

  # Request type is based on the destination tube from the source plate
  def request_type_between(_, destination)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between
end
