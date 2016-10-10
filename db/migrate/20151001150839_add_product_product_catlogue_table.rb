# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddProductProductCatlogueTable < ActiveRecord::Migration

  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up


    create_table :product_product_catalogues do |t|
      t.integer :product_id, null: false
      t.integer :product_catalogue_id, null: false
      t.string  :selection_criterion
      t.timestamps
    end
    add_constraint('product_product_catalogues','products')
    add_constraint('product_product_catalogues','product_catalogues')
  end

  def self.down
    drop_constraint('product_product_catalogues','products')
    drop_constraint('product_product_catalogues','product_catalogues')
    drop_table :product_product_catalogues
  end
end
