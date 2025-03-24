# frozen_string_literal: true
class LibPoolNormTubeGenerator
  include ActiveModel::Validations

  attr_accessor :plate
  attr_reader :user, :asset_group, :study

  validates :plate, presence: { message: 'Barcode does not relate to any existing plate' }
  validates :user, :study, presence: true

  validate :check_state, :check_plate_purpose, if: Proc.new { |g| g.plate.present? }

  def initialize(barcode, user, study)
    self.plate = barcode
    @user = user
    @study = study
  end

  def transfer_template
    @transfer_template ||= TransferTemplate.find_by!(transfer_class_name: 'Transfer::BetweenTubesBySubmission')
  end

  def plate=(barcode)
    @plate = set_plate(barcode)
  end

  def set_plate(barcode)
    Plate.with_barcode(barcode).includes(wells: { requests: %i[request_type target_asset] }).first
  end

  def lib_pool_tubes
    @lib_pool_tubes ||=
      plate
        .children
        .select { |c| c.is_a?(StockMultiplexedLibraryTube) }
        .reject { |tube| ['failed', 'qc_complete', 'cancelled'].include?(tube.state) }
  end

  def destination_tubes
    @destination_tubes ||= []
  end

  # rubocop:todo Metrics/MethodLength
  def create! # rubocop:todo Metrics/AbcSize
    if valid?
      begin
        ActiveRecord::Base.transaction do
          lib_pool_tubes.each do |tube|
            pass_and_complete(tube)
            pass_and_complete(create_lib_pool_norm_tube(tube))
          end

          @asset_group =
            AssetGroup.create!(
              assets: destination_tubes.map(&:receptacle),
              study: study,
              name: "#{plate.human_barcode}_qc_completed_tubes"
            )
        end
        true
      rescue => e
        Rails.logger.error("Pool generation error: #{e.message}")
        Rails.logger.error(e.backtrace)
        false
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  private

  def create_lib_pool_norm_tube(tube)
    destination_tube = transfer_template.create!(user: user, source: tube).destination
    destination_tubes << destination_tube
    destination_tube
  end

  def pass_and_complete(tube)
    StateChange.create!(user: user, target: tube, target_state: 'passed')
    StateChange.create!(user: user, target: tube, target_state: 'qc_complete')
  end

  def check_state
    errors.add(:plate, 'should be qc completed') unless plate.state == 'qc_complete'
  end

  def check_plate_purpose
    errors.add(:plate, 'should be of type Lib PCR-XP') unless plate.plate_purpose.name == 'Lib PCR-XP'
  end
end
