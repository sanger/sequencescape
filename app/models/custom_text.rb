# frozen_string_literal: true
# Used in a handful of places to provide dynamically customizable text in the
# web interface, such as setting the banner at the top of the page.
# @see ApplicationHelper::custom_text
class CustomText < ApplicationRecord
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
