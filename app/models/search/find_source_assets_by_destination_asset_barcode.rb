#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Search::FindSourceAssetsByDestinationAssetBarcode < Search
  def scope(criteria)
    Asset.source_assets_from_machine_barcode(criteria['barcode'])
  end
end
