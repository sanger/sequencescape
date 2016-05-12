class AddBespokeRnaProduct < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      DNA_LIBRARIES = []
      RNA_LIBRARIES = ['Small RNA']

      def add_criteria(product_catalogue, product, library_type_name, configuration)
        ProductCriteria.create!(:product => product,
          :stage => 'stock',
          :configuration => configuration)
        ProductProductCatalogue.create!(:product_catalogue => pc, :product => product, :selection_criterion => library_type_name)
      end

      pc = ProductCatalogue.find_by_name!("GenericPCR")
      product = Product.find_or_create_by_name('Bespoke RNA')


      DNA_CONFIG = {
          :concentration => { :less_than => 1},
          :rin => {:less_than => 6},
          :gender_markers => {}
        }

      RNA_CONFIG = {
          :concentration => { :less_than => 1},
          :rin => {:less_than => 6},
          :gender_markers => {}
        }

      DNA_LIBRARIES.each do |library_type_name|
        add_criteria(pc, product, library_type_name, DNA_CONFIG)
      end

      RNA_LIBRARIES.each do |library_type_name|
        add_criteria(pc, product, library_type_name, RNA_CONFIG)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      product = Product.find_by_name('Bespoke RNA')

      ProductProductCatalogue.find(:all, :conditions => { :product_id => product.id}).each(&:destroy)
    end
  end
end
