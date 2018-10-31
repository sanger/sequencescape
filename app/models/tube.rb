class Tube < Receptacle
  include Barcode::Barcodeable
  include ModelExtensions::Tube
  include Tag::Associations
  include Asset::Ownership::Unowned
  include Transfer::Associations
  include Transfer::State::TubeState
  include Api::Messages::QcResultIO::TubeExtensions

  extend QcFile::Associations

  # Fallback for tubes without a purpose
  self.default_prefix = 'NT'

  has_qc_files

  def automatic_move?
    true
  end

  def subject_type
    'tube'
  end

  def barcode!
    self.sanger_barcode = { number: AssetBarcode.new_barcode, prefix: default_prefix } unless barcode_number
    save!
  end

  scope :include_scanned_into_lab_event, -> { includes(:scanned_into_lab_event) }
  scope :with_purpose, ->(*purposes) { where(plate_purpose_id: purposes) }

  delegate :source_purpose, to: :purpose, allow_nil: true

  def submission
    submissions.first
  end

  def pool_id
    submissions.ids.first
  end

  def source_plate
    return nil if purpose.nil?
    @source_plate ||= purpose.source_plate(self)
  end

  def ancestor_of_purpose(ancestor_purpose_id)
    return self if plate_purpose_id == ancestor_purpose_id
    ancestors.order(created_at: :desc).find_by(plate_purpose_id: ancestor_purpose_id)
  end

  alias_method :friendly_name, :human_barcode

  def self.delegate_to_purpose(*methods)
    methods.each do |method|
      class_eval("def #{method}(*args, &block) ; purpose.#{method}(self, *args, &block) ; end")
    end
  end

  # TODO: change column name to account for purpose, not plate_purpose!
  belongs_to :purpose, class_name: 'Tube::Purpose', foreign_key: :plate_purpose_id
  delegate_to_purpose(:transition_to, :stock_plate)
  delegate :barcode_type, to: :purpose

  def name_for_label
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? name : primary_aliquot.sample.shorten_sanger_sample_id
  end

  def name_for_child_tube
    name
  end

  def details
    purpose.try(:name) || 'Tube'
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes.delete(:barcode)
    prefix     = attributes.delete(:barcode_prefix)&.prefix || default_prefix
    if barcode.present?
      human = SBCF::SangerBarcode.new(prefix: prefix, number: barcode).human_barcode
      raise "Barcode: #{barcode} already used!" if Barcode.where(barcode: human).exists?
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
