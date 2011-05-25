# Here are a load of searches that can be performed through the API.
Search::FindAssetByBarcode.create!(:name => 'Find asset by barcode')
Search::FindModelByName.create!(:name => 'Find project by name', :model_name => 'Project')
Search::FindModelByName.create!(:name => 'Find study by name',   :model_name => 'Study')
Search::FindModelByName.create!(:name => 'Find sample by name',  :model_name => 'Sample')
Search::FindSourceAssetsByDestinationAssetBarcode.create!(:name => 'Find source assets by destination asset barcode')
Search::FindUserByLogin.create!(:name => 'Find user by login')
Search::FindUserByswipecardCode.create!(:name => 'Find user by swipecard code')
