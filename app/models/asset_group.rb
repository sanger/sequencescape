# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class AssetGroup < ActiveRecord::Base
  include Uuid::Uuidable
  include ModelExtensions::AssetGroup
  include SharedBehaviour::Named

  belongs_to :study
  belongs_to :user
  belongs_to :submission # Optional, present if created by a particular submission

  has_many :asset_group_assets
  has_many :assets, through: :asset_group_assets

  validates :name, presence: true, uniqueness: true
  validates :study, presence: true

 scope :for_search_query, ->(query, _with_includes) { where(['name LIKE ?', "%#{query}%"]) }

  def all_samples_have_accession_numbers?
    unaccessioned_samples.count == 0
  end

  def unaccessioned_samples
    Sample.joins(:aliquots, :sample_metadata)
      .where(aliquots: { receptacle_id: assets.map(&:id) }, sample_metadata: { sample_ebi_accession_number: nil })
  end

  def self.find_or_create_asset_group(new_assets_name, study)
    # Is new name set or create group
    asset_group = nil
    if new_assets_name.present?
      asset_group = AssetGroup.create_with(study: study).find_or_create_by(name: new_assets_name)
    end
    asset_group
  end

  def automatic_move?
    asset_types.one? && assets.first.automatic_move?
  end

  def asset_types
    assets.map(&:sti_type).uniq
  end

  def duplicate(project)
    # TODO: Implement me
  end

  def move(assets)
    # TODO: Implement me
  end
end
