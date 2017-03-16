# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable
  include Barcode::Barcodeable
  include ModelExtensions::Tube
  include Tag::Associations
  include Asset::Ownership::Unowned
  include Transfer::Associations
  include Transfer::State::TubeState

  extend QcFile::Associations
  has_qc_files

  # Transfer requests into a tube are direct requests where the tube is the target.
  def transfer_requests
    requests_as_target.where_is_a?(TransferRequest)
  end

  def automatic_move?
    true
  end

  def subject_type
    'tube'
  end

  def barcode!
    self.barcode ||= AssetBarcode.new_barcode
    save!
  end

  has_many :submissions, ->() { distinct }, through: :requests_as_target
  scope :include_scanned_into_lab_event, -> { includes(:scanned_into_lab_event) }

 scope :with_purpose, ->(*purposes) {
    where(plate_purpose_id: purposes.flatten.map(&:id))
                      }

  def submission
    submissions.first
  end

  def source_plate
    return nil if purpose.nil?
    purpose.source_plate(self)
  end

  def ancestor_of_purpose(ancestor_purpose_id)
    return self if plate_purpose_id == ancestor_purpose_id
    ancestors.order(created_at: :desc).find_by(plate_purpose_id: ancestor_purpose_id)
  end

  def original_stock_plates
    ancestors.where(plate_purpose_id: PlatePurpose.stock_plate_purpose)
  end

  alias_method :friendly_name, :sanger_human_barcode

  def self.delegate_to_purpose(*methods)
    methods.each do |method|
      class_eval("def #{method}(*args, &block) ; purpose.#{method}(self, *args, &block) ; end")
    end
  end

  # TODO: change column name to account for purpose, not plate_purpose!
  belongs_to :purpose, class_name: 'Tube::Purpose', foreign_key: :plate_purpose_id
  delegate_to_purpose(:transition_to, :created_with_request_options, :pool_id, :name_for_child_tube, :stock_plate)
  delegate :barcode_type, to: :purpose

  def name_for_label
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? name : primary_aliquot.sample.shorten_sanger_sample_id
  end

  def details
    purpose.try(:name) || 'Tube'
  end

  def transfer_request_type_from(source)
    purpose.transfer_request_type_from(source.purpose)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes[:barcode]
    raise "Barcode: #{barcode} already used!" if barcode.present? and find_by(barcode: barcode).present?
    barcode ||= AssetBarcode.new_barcode
    create!(attributes.merge(barcode: barcode), &block)
  end
end

require_dependency 'sample_tube'
require_dependency 'library_tube'
require_dependency 'qc_tube'
require_dependency 'pulldown_multiplexed_library_tube'
require_dependency 'pac_bio_library_tube'
require_dependency 'stock_library_tube'
require_dependency 'stock_multiplexed_library_tube'
require_dependency 'stock_sample_tube'
