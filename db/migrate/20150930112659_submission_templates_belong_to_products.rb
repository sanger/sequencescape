#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class SubmissionTemplatesBelongToProducts < ActiveRecord::Migration
  def self.up
    default_template_id = Product.find_by_name('Generic').id
    add_column :submission_templates, :product_id, :integer, :null => :false, :default => default_template_id
  end

  def self.down
    remove_column :submission_templates, :product_id
  end
end
