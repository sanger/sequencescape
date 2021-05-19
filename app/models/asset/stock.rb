module Asset::Stock # rubocop:todo Style/Documentation
  # Extending this module will allow an asset to have a stock asset and be able to
  # create it.
  module CanCreateStockAsset
    # rubocop:todo Metrics/MethodLength
    def self.extended(base) # rubocop:todo Metrics/AbcSize
      base.class_eval do
        stock_asset_type_name = stock_asset_type.name
        has_one_as_child(:stock_asset, -> { where(sti_type: stock_asset_type_name) })

        def create_stock_asset!(attributes = {}, &block)
          self.class.stock_asset_purpose.create!(
            attributes.reverse_merge(name: "(s) #{name}", aliquots: aliquots.map(&:dup)),
            &block
          )
        end

        def new_stock_asset(attributes = {}, &block)
          self.class.stock_asset_type.new(
            attributes.reverse_merge(
              name: "(s) #{name}",
              aliquots: aliquots.map(&:dup),
              purpose: self.class.stock_asset_purpose
            ),
            &block
          )
        end

        delegate :is_a_stock_asset?, to: 'self.class'
      end
    end

    # rubocop:enable Metrics/MethodLength

    # By being able to create a stock asset the asset itself is not a stock.
    def is_a_stock_asset?
      false
    end
  end

  def has_stock_asset?
    false
  end

  def is_a_stock_asset?
    true
  end
end
