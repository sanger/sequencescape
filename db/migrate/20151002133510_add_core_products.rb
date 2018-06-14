
class AddCoreProducts < ActiveRecord::Migration
  require './lib/product_helpers'
  SINGLE_PRODUCTS = %w(
    MWGS
    PWGS
    ISC
    SC
    HSqX
    PFHSqX
    ReISC
    PacBio
    Fluidigm
    InternalQC
    Genotyping
  )

  COMPLEX_PRODUCTS = [
    {
      name: 'GenericPCR',
      selection_behaviour: 'LibraryDriven',
      products: {
        nil => 'Generic'
      },
    },
    {
      name: 'GenericNoPCR',
      selection_behaviour: 'LibraryDriven',
      products: {
        nil => 'Generic'
      },
    },
    {
      name: 'ClassicMultiplexed',
      selection_behaviour: 'LibraryDriven',
      products: {
        nil => 'Generic'
      }
    },
    {
      name: 'Manual',
      selection_behaviour: 'Manual',
      products: {
        nil => 'Generic',
        'MWGS' => 'MWGS',
        'PWGS' => 'PWGS',
        'ISC'  => 'ISC',
        'HSqX' => 'HSqX'
      }
    }
  ]

  def self.up
    ActiveRecord::Base.transaction do
      SINGLE_PRODUCTS.each do |name|
        ProductCatalogue.construct!(ProductHelpers.single_template(name))
      end
      COMPLEX_PRODUCTS.each do |params|
        ProductCatalogue.construct!(params)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SINGLE_PRODUCTS.each do |name|
        Product.find_by(name: name).delete
        ProductCatalogue.find_by(name: name).destroy
      end
      COMPLEX_PRODUCTS.each do |params|
        pc = ProductCatalogue.find_by(name: params[:name])
        pc.products.each(&:delete)
        pc.destroy
      end
    end
  end
end
