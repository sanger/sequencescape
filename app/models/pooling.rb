class Pooling
  include ActiveModel::Model

  attr_accessor :source_assets_ids, :source_assets, :stock_mx_tube_required, :stock_mx_tube, :standard_mx_tube

  validates_presence_of :source_assets
  validate :source_assets_are_in_sqsc
  validate :source_assets_can_be_pooled

  def execute
    if stock_mx_tube_required
      @stock_mx_tube = Tube::Purpose.stock_mx_tube.create!
      transfer_to(stock_mx_tube)
    end
    @standard_mx_tube = Tube::Purpose.standard_mx_tube.create!
    transfer_to(standard_mx_tube)
  end

  def transfer_to(target_asset)
    source_assets.each do |source_asset|
      RequestType.transfer.create!(asset: source_asset, target_asset: target_asset)
    end
  end

  def source_assets_ids=(source_assets_ids)
    @source_assets_ids = source_assets_ids
    @source_assets = Asset.where(id: source_assets_ids)
  end


  private

  def source_assets_are_in_sqsc
    assets_not_in_sqsc = (source_assets_ids || []) - source_assets.pluck(:id)
    errors.add(:source_assets, "with id(s) #{assets_not_in_sqsc.join(', ')} were not found in sequencescape") unless assets_not_in_sqsc.empty?
  end

  def source_assets_can_be_pooled
    assets_with_no_aliquot = []
    tags_combinations = []
    source_assets.each do |asset|
      if asset.aliquots.empty?
        assets_with_no_aliquot << asset.id
      else
        asset.aliquots.each { |aliquot| tags_combinations << aliquot.tags_combination }
      end
    end
    errors.add(:source_assets, "with id(s) #{assets_with_no_aliquot.join(', ')} do not have any aliquots") unless assets_with_no_aliquot.empty?
    errors.add(:tags_combinations, 'are not unique') unless tags_combinations.length == tags_combinations.uniq.length
  end

end