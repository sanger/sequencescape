class Event::SequenomLoading < Event
  def self.created_update_gender_makers!(asset, resource)
     self.create!(
       :eventful => asset,
       :message => "Updated gender results from #{resource}",
       :content => resource,
       :family => "update_gender_markers"
     )
   end

   def self.created_update_sequenom_count!(asset, resource)
      self.create!(
        :eventful => asset,
        :message => "Updated sequenom results from #{resource}",
        :content => resource,
        :family => "update_sequenom_count"
      )
    end
end