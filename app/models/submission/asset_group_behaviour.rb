# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Submission::AssetGroupBehaviour
  def self.included(base)
    base.class_eval do
      belongs_to    :asset_group
      before_create :find_asset_group,             unless: :asset_group?
      before_create :pull_assets_from_asset_group, if: :asset_group?

      # Required once out of the building state ...
      validates_presence_of :assets, if: :assets_need_validating?
    end
  end

  # Assets need validating if we are putting this order into a submission and the asset group has not been
  # specified in some form.
  def assets_need_validating?
    not building? and not (asset_group? or not asset_group_name.blank?)
  end
  private :assets_need_validating?

  def complete_building
    create_our_asset_group unless asset_group? or assets.blank?
    super
  end

  def asset_group?
    asset_group_id.present? or asset_group.present?
  end
  private :asset_group?

  def pull_assets_from_asset_group
    self.assets = asset_group.assets unless asset_group.assets.empty?
    true
  end
  private :pull_assets_from_asset_group

  # NOTE: We cannot name this method 'create_asset_group' because that's provided by 'has_one :asset_group'!
  def create_our_asset_group
    return nil if study.nil? && cross_study_allowed
    group_name = asset_group_name
    group_name = uuid if asset_group_name.blank?

    asset_group = study.asset_groups.create!(
      name: group_name,
      user: user,
      assets: assets
    )
    update_attributes!(asset_group_id: asset_group.id)
  end
  private :create_our_asset_group

  def find_asset_group
    self.asset_group = study.asset_groups.find_by(name: asset_group_name) unless asset_group_name.blank?
    true
  end
  private :find_asset_group
end
