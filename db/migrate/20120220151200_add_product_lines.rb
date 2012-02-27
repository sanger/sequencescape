class ProductLine < ActiveRecord::Base; end
 
class AddProductLines < ActiveRecord::Migration
  def self.up
    create_table :product_lines do |t|
      t.string :name, :null => false
    end


    ActiveRecord::Base.transaction do
      %w{Illumina-A Illumina-B Illumina-C}.each do |pipeline_name|
        say "Adding default Product Lines for #{pipeline_name}."
        ProductLine.create!(:name => pipeline_name)
      end
    end
  end

  def self.down
    drop_table :product_lines
  end
end
