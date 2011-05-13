class CustomText < ActiveRecord::Base
  after_save :clear_text_cache!
  
  def clear_text_cache!
    Rails.cache.delete(identifier)
  end
end
