#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class UpdateProductLineForAllTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      plid= ProductLine.find_by_name('Illumina-C').id
      SubmissionTemplate.update_all("product_line_id=#{plid}",'name LIKE("Illumina-C%")')
    end
  end

  def self.down
    raise "No down migration"
  end
end
