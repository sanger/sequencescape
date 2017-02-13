# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class AssetGroupAsset < ActiveRecord::Base
  default_scope ->() { includes(:asset, :asset_group) }
  belongs_to :asset, class_name: 'Aliquot::Receptacle', inverse_of: :asset_group_assets
  belongs_to :asset_group, inverse_of: :asset_group_assets
end
