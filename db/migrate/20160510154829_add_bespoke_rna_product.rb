class AddBespokeRnaProduct < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      pc = ProductCatalogue.find_by_name!("GenericPCR")
      rna_library = LibraryType.find_by_name!('Small RNA')
      product = Product.find_or_create_by_name('Bespoke RNA')

      ProductCriteria.create!(:product => product,
        :stage => 'stock',
        :configuration => {
        :concentration => { :less_than => 1},
        :rin => {:less_than => 6},
        :sanger_sample_id => {},
        :plate_barcode => {},
        :well_location => {},
        :supplier_name => {},
        :current_volume => {},
        :total_micrograms => {},
        :gender => {},
        :gender_markers => {}
      })

      ProductProductCatalogue.create!(:product_catalogue => pc, :product => product, :selection_criterion => rna_library.name)

    end
  end

  def down
    ActiveRecord::Base.transaction do
      product = Product.find_by_name('Bespoke RNA')

      ProductProductCatalogue.find(:all, :conditions => { :product_id => product.id}).each(&:destroy)
    end
  end
end
