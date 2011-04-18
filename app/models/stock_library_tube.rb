class StockLibraryTube < Asset
  include LocationAssociation::Locatable
  def is_a_pool?
    false
  end
  
  def has_stock_asset?
    false
  end
  
  def is_a_stock_asset?
    true
  end
end
