# frozen_string_literal: true
class SampleTube < Tube
  include Api::SampleTubeIo::Extensions
  include StandardNamedScopes

  self.stock_message_template = 'TubeStockResourceIo'

  before_create :generate_barcode, unless: :primary_barcode
  after_create :generate_name_from_aliquots, unless: :name?

  # All instances are labelled 'SampleTube', unless otherwise specified
  before_validation { |record| record.label = 'SampleTube' if record.label.blank? }

  private

  def generate_name_from_aliquots
    return if name.present? || primary_aliquot.try(:sample).nil?

    self.name = primary_aliquot.sample.name
    save!
  end
end
