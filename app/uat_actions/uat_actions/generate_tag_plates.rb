# frozen_string_literal: true

# Will construct plates with well_count wells filled with samples
class UatActions::GenerateTagPlates < UatActions
  self.title = 'Generate tag plates'
  self.description =
    'Generate available tag plates. All tag plates will be part of a new lot. For generation of plates ' \
    'of pretagged samples see "Generate Tagged Plates".'
  self.category = :auxiliary_data

  form_field :tag_layout_template_name,
             :select,
             label: 'Tag Layout Template',
             help: 'Select the tag layout for the generated plates',
             select_options:
               lambda { TagLayoutTemplate.where.not(walking_algorithm: 'TagLayout::WalkWellsByPools').pluck(:name) }
  form_field :lot_type_name,
             :select,
             label: 'Lot Type',
             help: 'The lot type to use.',
             select_options: lambda { LotType.where(template_class: 'TagLayoutTemplate').pluck(:name) }
  form_field :plate_count,
             :number_field,
             label: 'Plate Count',
             help: 'The number of plates to generate',
             options: {
               minimum: 1,
               maximum: 20
             }

  validates :tag_layout_template, presence: { message: 'could not be found' }
  validates :lot_type, presence: { message: 'could not be found' }

  def self.default
    new(plate_count: 4)
  end

  def perform
    qcc = QcableCreator.create!(lot: lot, user: user, count: plate_count.to_i)
    qcc.qcables.each_with_index do |qcable, index|
      qcable.update!(state: 'available')
      report["tag_plate_#{index}"] = qcable.asset.machine_barcode
    end
  end

  private

  def user
    UatActions::StaticRecords.user
  end

  def lot
    @lot ||=
      lot_type.lots.create!(
        lot_number: "UAT#{Time.current.to_f}",
        template: tag_layout_template,
        user: user,
        received_at: Time.current
      )
  end

  def lot_type
    @lot_type ||= LotType.find_by(name: lot_type_name)
  end

  def tag_layout_template
    @tag_layout_template ||= TagLayoutTemplate.find_by(name: tag_layout_template_name)
  end
end
