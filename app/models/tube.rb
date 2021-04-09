# A Tube is a piece of {Labware}
class Tube < Labware
  include Barcode::Barcodeable
  include ModelExtensions::Tube
  include Tag::Associations
  include Asset::Ownership::Unowned
  include Transfer::Associations
  include Transfer::State::TubeState
  include Api::Messages::QcResultIO::TubeExtensions
  include SingleReceptacleLabware

  extend QcFile::Associations

  # Fallback for tubes without a purpose
  self.default_prefix = 'NT'
  self.automatic_move = true

  has_qc_files

  def subject_type
    'tube'
  end

  def barcode!
    self.sanger_barcode = { number: AssetBarcode.new_barcode, prefix: default_prefix } unless barcode_number
    save!
  end

  delegate :source_purpose, to: :purpose, allow_nil: true

  def comments
    @comments ||= CommentsProxy::Tube.new(self)
  end

  def submission
    submissions.first
  end

  def pool_id
    submissions.ids.first
  end

  def name_for_label
    primary_sample&.shorten_sanger_sample_id.presence || name
  end

  alias friendly_name human_barcode

  # Delegates the provided methods to purpose, passing the tube as the first argument, and the remaining arguments as-is
  def self.delegate_to_purpose(*methods)
    methods.each do |method|
      class_eval("def #{method}(*args, &block) ; purpose.#{method}(self, *args, &block) ; end")
    end
  end

  # TODO: change column name to account for purpose, not plate_purpose!
  belongs_to :purpose, class_name: 'Tube::Purpose', foreign_key: :plate_purpose_id
  has_one :racked_tube, dependent: :destroy
  has_one :tube_rack, through: :racked_tube

  scope :in_column_major_order, lambda {
    joins(:racked_tube).order('racked_tubes.coordinate ASC')
  }
  delegate :coordinate, to: :racked_tube

  # @!method stock_plate
  #   Returns the stock plate of the tube, behaviour delegated to purpose
  #   @return [Plate] The stock plate
  delegate_to_purpose(:stock_plate)

  delegate :barcode_type, to: :purpose

  def name_for_child_tube
    name
  end

  def sanger_barcode=(attributes)
    barcodes << Barcode.build_sanger_ean13(attributes)
  end

  def details
    purpose.try(:name) || 'Tube'
  end

  def after_comment_addition(comment)
    comments.add_comment_to_submissions(comment)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes.delete(:barcode)
    prefix     = attributes.delete(:barcode_prefix)&.prefix || default_prefix
    if barcode.present?
      human = SBCF::SangerBarcode.new(prefix: prefix, number: barcode).human_barcode
      raise "Barcode: #{barcode} already used!" if Barcode.exists?(barcode: human)
    end
    barcode ||= AssetBarcode.new_barcode
    primary_barcode = { prefix: prefix, number: barcode }
    create!(attributes.merge(sanger_barcode: primary_barcode), &block)
  end
end

require_dependency 'sample_tube'
require_dependency 'library_tube'
require_dependency 'qc_tube'
require_dependency 'pulldown_multiplexed_library_tube'
require_dependency 'pac_bio_library_tube'
require_dependency 'stock_library_tube'
require_dependency 'stock_multiplexed_library_tube'
