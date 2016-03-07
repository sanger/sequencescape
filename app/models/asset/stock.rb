#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2014 Genome Research Ltd.
module Asset::Stock
  # Extending this module will allow an asset to have a stock asset and be able to
  # create it.
  module CanCreateStockAsset
    def self.extended(base)
      base.class_eval do
        has_one_as_child(:stock_asset, :conditions=> {:sti_type => stock_asset_type.name} )

        stock_asset_factory(:create_stock_asset!, :create!)
        stock_asset_factory(:new_stock_asset, :new)
        deprecate :new_stock_asset

        delegate :is_a_stock_asset?, :to => 'self.class'
      end
    end

    # By being able to create a stock asset the asset itself is not a stock.
    def is_a_stock_asset?
      false
    end

    def stock_asset_factory(name, ctor)
      line = __LINE__
      class_eval(%Q{
        def #{name}(attributes = {}, &block)
          self.class.stock_asset_type.#{ctor}(attributes.reverse_merge(
            :name     => "(s) \#{self.name}",
            :barcode  => AssetBarcode.new_barcode,
            :aliquots => self.aliquots.map(&:dup),
            :purpose  => self.class.stock_asset_purpose
          ), &block)
        end
      }, __FILE__, line)
    end
  end

  def has_stock_asset?
    false
  end

  def is_a_stock_asset?
    true
  end
end
