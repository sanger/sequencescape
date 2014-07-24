class CustomText < ActiveRecord::Base
  after_save :clear_text_cache!

  # If the value of this CustomText instance was saved in cache
  # e.g. the appication wide information box, delete it.
  def clear_text_cache!
    Rails.cache.delete(name)
  end

  def name
    "#{identifier}-#{differential}"
  end
end
