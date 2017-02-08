# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class StockLibraryTubeTest < ActiveSupport::TestCase
  context 'A stock Library tube' do
    setup do
      @stock_library = create :stock_library_tube
    end

    context '#has_stock_asset?' do
      should 'return false' do
        assert !@stock_library.has_stock_asset?
      end
    end

    context '#is_a_stock_asset?' do
      should 'return true' do
        assert @stock_library.is_a_stock_asset?
      end
    end
  end
end
