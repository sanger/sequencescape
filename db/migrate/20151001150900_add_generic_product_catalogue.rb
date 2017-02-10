# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

class AddGenericProductCatalogue < ActiveRecord::Migration
  class ProductProductCatalogue < ActiveRecord::Base
    self.table_name = ('product_product_catalogues')
  end

  class ProductCatalogue < ActiveRecord::Base
    self.table_name = ('product_catalogues')
  end

  class Product < ActiveRecord::Base
    self.table_name = ('products')
  end

  def self.up
    ActiveRecord::Base.transaction do
      pc = ProductCatalogue.create!(name: 'Generic')
      ProductProductCatalogue.create!(product_id: Product.find_by!(name: 'Generic').id, product_catalogue_id: pc.id)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      pc = ProductCatalogue.find_by(name: 'Generic')
      ProductProductCatalogue.find_by(product_catalogue_id: pc.id).destroy
      ProductCatalogue.find_by(name: 'Generic').destroy
    end
  end
end
