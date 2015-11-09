#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class IlluminaHtp::PooledPlatePurpose < PlatePurpose
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      super
      if (state=='passed')
        plate.wells.with_aliquots.include_stock_wells.find(:all,:select=>'DISTINCT assets.*').each do |well|
          # As we've already loaded the requests along with the stock wells, the ruby way is about 4 times faster
          library_creation_request = well.stock_wells.first.requests.detect {|r| r.library_creation? }
          requests = library_creation_request.submission.obtain_next_requests_to_connect(library_creation_request)
          requests.reject {|r| r.asset.present? }.slice(0,12).each do |r|
            r.update_attributes!(:asset => well)
          end
        end
      end
    end
  end

end
