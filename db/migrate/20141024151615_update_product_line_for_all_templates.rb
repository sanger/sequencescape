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
