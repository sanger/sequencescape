
class SubmissionTemplatesBelongToProductCatalogues < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    add_column :submission_templates, :product_catalogue_id, :integer
    add_constraint('submission_templates', 'product_catalogues')
  end

  def self.down
    drop_constraint('submission_templates', 'product_catalogues')
    remove_column :submission_templates, :product_catalogue_id
  end
end
