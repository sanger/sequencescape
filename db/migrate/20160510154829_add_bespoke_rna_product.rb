class AddBespokeRnaProduct < ActiveRecord::Migration
  DNA_LIBRARIES = [
    # No DNA libraries
  ]
  RNA_LIBRARIES = [
    'RNA-seq dUTP',
    'RNA-seq dUTP eukaryotic',
    'RNA-seq dUTP prokaryotic',
    'Ribozero RNA depletion',
    'Ribozero RNA-seq (Bacterial)',
    'Ribozero RNA-seq (HMR)',
    'Small RNA',
    'TruSeq mRNA (RNA Seq)',
    'DAFT-seq'
  ]

  RNA_CONFIG = {
      concentration: { less_than: 1 },
      concentration_from_normalization: { less_than: 1 },
      rin: { less_than: 6 },
      gender_markers: {}
    }

  def product_catalogue
    @product_catalogue ||= ProductCatalogue.find_by!(name: 'GenericPCR')
  end

  def dna_product
    @dna_product ||= Product.find_by!(name: 'Generic')
  end

  def rna_product
    @rna_product ||= Product.find_or_create_by(name: 'Bespoke RNA')
  end

  def default_product
    link = ProductProductCatalogue.find_by(
      product_catalogue_id: product_catalogue.id,
      selection_criterion: nil
    )
    return link.product unless link.nil?
    dna_product
  end

  def link_product_to_catalogue(product, selection_criterion)
    ProductProductCatalogue.create!(product_catalogue: product_catalogue, product: product, selection_criterion: selection_criterion)
  end

  def unlink_product_from_catalogue(product, selection_criterion)
    ProductProductCatalogue.where(
      product_catalogue_id: product_catalogue.id,
      product_id: product.id,
      selection_criterion: selection_criterion
    ).each(&:destroy)
  end

  def process_dna_and_rna_with_action(action)
    # Default product for product catalogue library driven will be DNA
    send(action, default_product, nil)

    DNA_LIBRARIES.each do |library_type_name|
      # Check if it exists
      next unless LibraryType.find_by(name: library_type_name)
      send(action, dna_product, library_type_name)
    end

    RNA_LIBRARIES.each do |library_type_name|
      # Check if it exists
      next unless  LibraryType.find_by(name: library_type_name)
      send(action, rna_product, library_type_name)
    end
  end

  def up
    ActiveRecord::Base.transaction do
      ProductCriteria.create!(product: rna_product,
                              stage: 'stock',
                              configuration: RNA_CONFIG)
      process_dna_and_rna_with_action(:link_product_to_catalogue)
    end
  end

  def down
    ActiveRecord::Base.transaction do
      process_dna_and_rna_with_action(:unlink_product_from_catalogue)
    end
  end
end
