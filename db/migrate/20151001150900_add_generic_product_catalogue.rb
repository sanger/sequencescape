
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
