#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
ActiveRecord::Base.transaction do
  %w{Illumina-A Illumina-B Illumina-C}.each do |product_line_name|
    #say "Adding default Product Lines for #{product_line_name}."
    ProductLine.create!(:name => product_line_name)
  end
end
