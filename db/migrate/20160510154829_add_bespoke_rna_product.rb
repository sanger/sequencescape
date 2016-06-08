class AddBespokeRnaProduct < ActiveRecord::Migration

  DNA_LIBRARIES = [
    # No DNA libraries
  ]
  RNA_LIBRARIES = [
    "RNA-seq dUTP",
    "RNA-seq dUTP eukaryotic",
    "RNA-seq dUTP prokaryotic",
    "Ribozero RNA depletion",
    "Ribozero RNA-seq (Bacterial)",
    "Ribozero RNA-seq (HMR)",
    "Small RNA",
    "TruSeq mRNA (RNA Seq)",
    "DAFT-seq"
  ]

  RNA_CONFIG = {
      :concentration => { :less_than => 1},
      :concentration_from_normalization => { :less_than => 1},
      :rin => {:less_than => 6},
      :gender_markers => {}
    }

  def self.PRODUCT_CATALOGUE
    ProductCatalogue.find_by_name!("GenericPCR")
  end

  def self.DNA_PRODUCT
      Product.find_by_name('Generic')
  end

  def self.RNA_PRODUCT
      Product.find_or_create_by_name('Bespoke RNA')
  end

  def self.DEFAULT_PRODUCT
    link = ProductProductCatalogue.find(:first, :conditions => {
      :product_catalogue_id => self.PRODUCT_CATALOGUE.id,
      :selection_criterion => nil
    })
    return link.product unless link.nil?
    self.DNA_PRODUCT
  end

  def self.link_product_to_catalogue(product_catalogue, product, selection_criterion)
    ProductProductCatalogue.create!(:product_catalogue => product_catalogue, :product => product, :selection_criterion => selection_criterion)
  end

  def self.unlink_product_from_catalogue(product_catalogue, product, selection_criterion)
    ProductProductCatalogue.find(:all, :conditions => {
      :product_catalogue_id => product_catalogue.id,
      :product_id => product.id,
      :selection_criterion => selection_criterion
    }).each(&:destroy)
  end

  def self.process_dna_and_rna_with_action(action)
      product_catalogue = self.PRODUCT_CATALOGUE

      # Default product for product catalogue library driven will be DNA
      self.send(action, product_catalogue, self.DEFAULT_PRODUCT, nil)

      DNA_LIBRARIES.each do |library_type_name|
        # Check if it exists
        LibraryType.find_by_name!(library_type_name)
        self.send(action, product_catalogue, self.DNA_PRODUCT, library_type_name)
      end

      RNA_LIBRARIES.each do |library_type_name|
        # Check if it exists
        LibraryType.find_by_name!(library_type_name)
        self.send(action, product_catalogue, self.RNA_PRODUCT, library_type_name)
      end
  end

  def up
    ActiveRecord::Base.transaction do
      ProductCriteria.create!(:product => AddBespokeRnaProduct.RNA_PRODUCT,
        :stage => 'stock',
        :configuration => RNA_CONFIG)
      AddBespokeRnaProduct.process_dna_and_rna_with_action(:link_product_to_catalogue)
    end
  end

  def down
    ActiveRecord::Base.transaction do
      AddBespokeRnaProduct.process_dna_and_rna_with_action(:unlink_product_from_catalogue)
    end
  end
end
