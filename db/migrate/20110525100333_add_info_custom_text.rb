class AddInfoCustomText < ActiveRecord::Migration
  def self.app_info_box
    # The current design of CustomText doesn't support uniqueness
    # so we always use the first app_info_box-1 and hope that it's the
    # only one.
    CustomText.first(
      :conditions => {
        :identifier   => "app_info_box",
        :differential => "1"
      }
    )
  end
  
  def self.up
    if self.app_info_box.nil?
      CustomText.create!(
        :identifier   => "app_info_box",
        :differential => 1,
        :content_type => "text/html"
      )
    end
  end

  def self.down
    if self.app_info_box
      CustomText.delete_all(
        :identifier   => "app_info_box",
        :differential => 1
      )    
    end
  end
end
