# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class SubmissionTemplatesBelongToProductCatalogues < ActiveRecord::Migration

  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint


  def self.up
    add_column :submission_templates, :product_catalogue_id, :integer
    add_constraint('submission_templates','product_catalogues')
  end

  def self.down
    drop_constraint('submission_templates','product_catalogues')
    remove_column :submission_templates, :product_catalogue_id
  end
end
