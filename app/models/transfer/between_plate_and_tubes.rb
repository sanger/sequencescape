# frozen_string_literal: true
class Transfer::BetweenPlateAndTubes < Transfer
  DESTINATION_INCLUDES = { destination: %i[uuid_object barcodes] }.freeze

  class WellToTube < ApplicationRecord
    self.table_name = ('well_to_tube_transfers')

    belongs_to :transfer, class_name: 'Transfer::BetweenPlateAndTubes'
    validates :transfer, presence: true

    belongs_to :destination, class_name: 'Tube'
    validates :destination, presence: true

    validates :source, presence: true

    scope :include_destination, -> { includes(Transfer::BetweenPlateAndTubes::DESTINATION_INCLUDES) }
  end

  include Transfer::ControlledDestinations

  # Records the transfers from the wells on the plate to the assets they have gone into.
  has_many :well_to_tubes, class_name: 'Transfer::BetweenPlateAndTubes::WellToTube', foreign_key: :transfer_id
  has_many :destinations, -> { distinct }, through: :well_to_tubes
  scope :include_transfers, -> { includes(well_to_tubes: DESTINATION_INCLUDES) }

  after_create :build_well_to_tube_transfers

  def transfers
    well_to_tubes.include_destination.each_with_object({}) { |t, hash| hash[t.source] = tube_to_hash(t.destination) }
  end

  private

  # NOTE: Performance enhancement to convert a tube to it's minimal representation for presentation.
  def tube_to_hash(tube) # rubocop:todo Metrics/AbcSize
    # Only build the hash once per tube. Shows significant speed improvement, esp. with label_text
    @tubes ||= {}
    @tubes[tube.id] ||= {
      uuid: tube.uuid,
      name: tube.name,
      state: tube.state,
      label: {
        text: tube.purpose.name
      }
    }.tap do |details|
      barcode_to_hash(tube) { |s| details[:barcode] = s }
      barcode_to_hash(tube.source_plate) { |s| details[:stock_plate] = { barcode: s } }
      details[:label][:prefix] = tube.role unless tube.role.nil?
    end
  end

  def barcode_to_hash(barcoded)
    if barcoded.present?
      yield(
        {
          number: barcoded.barcode_number,
          prefix: barcoded.prefix,
          two_dimensional: barcoded.two_dimensional_barcode,
          ean13: barcoded.ean13_barcode,
          type: barcoded.barcode_type
        }
      )
    end
  end

  #--
  # The source plate wells need to be translated back to the stock plate wells, which simply
  # involves following the transfer requests back up until we hit the stock plate.  We only need
  # to follow one transfer request for each well as the submission related stock wells will be in
  # the same final well.  Once we get to the stock well we then find the request that has the
  # well as a source and the target is an MX library tube.
  #++
  def well_to_destination
    source
      .stock_wells
      .each_with_object({}) do |(well, stock_wells), store|
        tube = locate_mx_library_tube_for(well, stock_wells)
        next if tube.nil? || should_well_not_be_transferred?(well)

        store[well] = [tube, stock_wells]
      end
  end

  def record_transfer(source, destination, stock_well)
    @transfers ||= {}
    @transfers[source.map.description] = [destination, stock_well]
  end

  def build_well_to_tube_transfers # rubocop:todo Metrics/MethodLength
    tube_to_stock_wells = Hash.new { |h, k| h[k] = [] }

    well_to_tubes.build(
      @transfers.map do |source, (destination, stock_wells)|
        tube_to_stock_wells[destination].concat(stock_wells)
        { source:, destination: }
      end
    ).map(&:save!)

    tube_to_stock_wells.each do |tube, stock_wells|
      next unless apply_name?(tube)

      tube.update!(name: tube_name_for(stock_wells))
    end
  end

  def apply_name?(_)
    true
  end

  # Builds the name for the tube based on the wells that are being transferred from by finding their stock plate wells
  # and creating an appropriate range.
  def tube_name_for(stock_wells) # rubocop:todo Metrics/AbcSize
    source_wells =
      source.plate_purpose.source_wells_for(stock_wells).sort { |w1, w2| w1.map.column_order <=> w2.map.column_order }
    stock_plates = source_wells.map(&:plate).uniq
    raise StandardError, 'There appears to be no stock plate!' if stock_plates.empty?

    plate_name = stock_plates.size > 1 ? "#{stock_plates.first.human_barcode}+" : stock_plates.first.human_barcode
    first, last = source_wells.first.map_description, source_wells.last.map_description
    "#{plate_name} #{first}:#{last}"
  end

  def build_asset_links
    AssetLink::Job.create_now(source, destinations)
  end
end
