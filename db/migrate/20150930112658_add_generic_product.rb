# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddGenericProduct < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Product.create!(name: 'Generic')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Product.find_by(name: 'Generic').delete
    end
  end
end
