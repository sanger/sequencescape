# frozen_string_literal: true

# A barcode is an identifier for a piece of labware which is attached via a
# printed label. Barcodes may either be generated by Sequencescape, or may get
# supplied externally. In some cases labware may have more than one barcode assigned.
#
# @author [grl]
#
class Barcode < ApplicationRecord
  require 'sanger_barcode_format'
  require 'sanger_barcode_format/legacy_methods'
  extend SBCF::LegacyMethods

  belongs_to :asset, optional: false, class_name: 'Labware'
  before_validation :serialize_barcode

  # See #4121 - renaming asset terminology to labware
  # See #4121 - The actual table column will be renamed in a subsequent story
  alias_association :labware, :asset
  alias_attribute :labware_id, :asset_id

  after_commit :broadcast_barcode

  # Caution! Do not adjust the index of existing formats.
  enum format: {
         sanger_ean13: 0,
         infinium: 1,
         fluidigm: 2,
         external: 3,
         # gone. Don't do this.
         aker_barcode: 4,
         cgap: 5,
         sanger_code39: 6,
         fluidx_barcode: 7,
         uk_biocentre_v1: 8,
         uk_biocentre_v2: 9,
         uk_biocentre_unid: 10,
         alderly_park_v1: 11,
         alderly_park_v2: 12,
         uk_biocentre_v3: 13,
         cgap_plate: 14,
         cgap_rack: 15,
         glasgow: 16,
         cambridge_a_z: 17,
         heron_tailed: 18,
         randox: 19,
         uk_biocentre_v4: 20,
         cambridge_a_z_v2: 21,
         glasgow_v2: 22,
         eagle: 23,
         cambridge_a_z_eagle: 24,
         glasgow_eagle: 25,
         uk_biocentre_eagle: 26,
         alderley_park_eagle: 27,
         randox_eagle: 28,
         randox_v2: 29,
         glasgow_v3: 30,
         uk_biocentre_v5: 31,
         health_services_laboratories_v1: 32,
         uk_biocentre_v6: 33,
         brants_bridge: 34,
         leamington_spa: 35,
         newcastle: 36,
         brants_bridge_v2: 37,
         uk_biocentre_v7: 38,
         east_london_genes_and_health: 39,
         leamington_spa_v2: 40,
         east_london_genes_and_health_v2: 41,
         sequencescape22: 42,
         plymouth_v2: 43,
         leamington_spa_v3: 44,
         brants_bridge_v3: 45,
         ibd_response: 46,
         rvi: 47
       }

  # Barcode formats which may be submitted via sample manifests
  FOREIGN_BARCODE_FORMATS = %i[
    cgap
    fluidx_barcode
    fluidigm
    uk_biocentre_v1
    uk_biocentre_v2
    uk_biocentre_unid
    alderly_park_v1
    alderly_park_v2
    uk_biocentre_v3
    cgap_plate
    cgap_rack
    glasgow
    cambridge_a_z
    heron_tailed
    randox
    uk_biocentre_v4
    cambridge_a_z_v2
    glasgow_v2
    eagle
    cambridge_a_z_eagle
    glasgow_eagle
    uk_biocentre_eagle
    alderley_park_eagle
    randox_eagle
    randox_v2
    glasgow_v3
    uk_biocentre_v5
    health_services_laboratories_v1
    uk_biocentre_v6
    brants_bridge
    leamington_spa
    newcastle
    brants_bridge_v2
    uk_biocentre_v7
    east_london_genes_and_health
    leamington_spa_v2
    east_london_genes_and_health_v2
    sequencescape22
    plymouth_v2
    leamington_spa_v3
    brants_bridge_v3
    ibd_response
    rvi
  ].freeze

  validate :barcode_valid?
  validates :barcode, uniqueness: { scope: :format, case_sensitive: false }
  scope(
    :sanger_barcode,
    lambda do |prefix, number|
      human_barcode = SBCF::SangerBarcode.from_prefix_and_number(prefix, number).human_barcode
      where(format: %i[sanger_ean13 sanger_code39], barcode: human_barcode)
    end
  )
  scope :for_search_query, ->(*input) { where(barcode: Barcode.extract_barcodes(input)).includes(:asset) }

  delegate :=~, to: :handler
  delegate_missing_to :handler

  def self.build_sanger_ean13(attributes)
    build_sanger_barcode(attributes, format: :sanger_ean13)
  end

  def self.build_sanger_code39(attributes)
    build_sanger_barcode(attributes, format: :sanger_code39)
  end

  def self.build_sequencescape22(attributes)
    new(format: :sequencescape22, barcode: attributes[:barcode])
  end

  def self.build_sanger_barcode(attributes, format:)
    # We need to symbolize our hash keys to allow them to get passed in to named arguments.
    safe_attributes = attributes.slice(:number, :prefix, :human_barcode, :machine_barcode).symbolize_keys
    new(format: format, barcode: SBCF::SangerBarcode.new(**safe_attributes).human_barcode)
  end

  # Extract barcode from user input
  def self.extract_barcode(barcode)
    [barcode.to_s].tap { |barcodes| barcodes << SBCF::SangerBarcode.from_user_input(barcode.to_s).human_barcode }
      .compact.uniq
  end

  # Returns the barcode format matching the supplied barcode
  def self.matching_barcode_format(possible_barcode)
    FOREIGN_BARCODE_FORMATS.detect do |cur_format|
      bc = Barcode.new(format: cur_format, barcode: possible_barcode)
      bc.handler.valid?
    end
  end

  def self.exists_for_format?(barcode_format, search_barcode)
    Barcode.exists?(format: barcode_format, barcode: search_barcode)
  end

  def self.extract_barcodes(barcodes)
    barcodes
      .flatten
      .each_with_object([]) do |source_bc, store|
        next if source_bc.blank?

        store.concat(Barcode.extract_barcode(source_bc))
      end
  end

  def sequencescape22?
    format == 'sequencescape22'
  end

  def handler
    @handler ||= handler_class.new(barcode)
  end

  def handler_class_name
    format.classify
  end

  # If the barcode changes, we'll need a new handler. This allows handlers themselves to be immutable.
  def barcode=(new_barcode)
    @handler = nil
    super
  end

  def sanger_barcode?
    sanger_ean13? || sanger_code39?
  end

  def child_barcodes
    Barcode.where('barcode LIKE ?', "#{barcode}-%")
  end

  # See #4121 - renaming asset terminology to labware
  def labware
    asset
  end

  # See #4121 - renaming asset terminology to labware
  # rubocop:disable Naming/AccessorMethodName
  def labware=(labware)
    self.asset = labware
  end
  # rubocop:enable Naming/AccessorMethodName

  private

  def barcode_valid?
    errors.add(:barcode, "is not an acceptable #{format} barcode") unless handler.valid?
  end

  def handler_class
    Barcode::FormatHandlers.const_get(handler_class_name, false)
  end

  def broadcast_barcode
    Messenger.new(template: 'BarcodeIO', root: 'barcode', target: self).broadcast
  end

end
