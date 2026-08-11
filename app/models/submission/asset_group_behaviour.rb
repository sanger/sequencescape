# frozen_string_literal: true
module Submission::AssetGroupBehaviour
  def self.included(base)
    base.class_eval do
      belongs_to :asset_group
      before_create :find_asset_group, unless: :asset_group?
      before_create :pull_assets_from_asset_group, if: :asset_group?

      # Required once out of the building state ...
      validates :assets, presence: { if: :assets_need_validating? }
    end
  end

  def complete_building_asset_group
    create_our_asset_group unless asset_group? || assets.blank?
  end

  private

  # Assets need validating if we are putting this order into a submission and the asset group has not been
  # specified in some form.
  def assets_need_validating?
    not building? and not (asset_group? or asset_group_name.present?)
  end

  def asset_group?
    asset_group_id.present? or asset_group.present?
  end

  def pull_assets_from_asset_group
    self.assets = asset_group.assets unless asset_group.assets.empty?
    true
  end

  # NOTE: We cannot name this method 'create_asset_group' because that's provided by 'has_one :asset_group'!
  def create_our_asset_group
    return nil if study.nil? && cross_study_allowed

    group_name = asset_group_name
    group_name = uuid if asset_group_name.blank?

    asset_group = study.asset_groups.create!(name: group_name, user: user, assets: assets)
    update!(asset_group_id: asset_group.id)
  end

  def find_asset_group
    self.asset_group = study.asset_groups.find_by(name: asset_group_name) if asset_group_name.present?
    true
  end
end
