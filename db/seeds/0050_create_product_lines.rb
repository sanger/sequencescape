ActiveRecord::Base.transaction do
  %w{Illumina-A Illumina-B Illumina-C}.each do |product_line_name|
    #say "Adding default Product Lines for #{product_line_name}."
    ProductLine.create!(:name => product_line_name)
  end
end