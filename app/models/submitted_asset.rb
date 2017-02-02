# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class SubmittedAsset < ActiveRecord::Base
  belongs_to :order
  belongs_to :asset, class_name: 'Aliquot::Receptacle'

  validates_presence_of :order, inverse_of: :submitted_assets
  validates_presence_of :asset, inverse_of: :submitted_assets
end
