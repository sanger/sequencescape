class AddPoolingMethodsToRequestTypes < ActiveRecord::Migration

  class PoolingMethod < ActiveRecord::Base
    serialize :pooling_options
  end

  class RequestType < ActiveRecord::Base
    belongs_to :pooling_method, :class_name => 'AddPoolingMethodsToRequestTypes::PoolingMethod'
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.reset_column_information
      RequestType.find_by_key('illumina_htp_library_creation').tap do |rt|
        rt.pooling_method = PoolingMethod.create!(
          :pooling_behaviour => 'PlateRow',
          :pooling_options   => {:pool_count=>8}
        )
        rt.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_htp_library_creation').pooling_method.find_by_pooling_behaviour('PlateRow').destroy
    end
  end
end
