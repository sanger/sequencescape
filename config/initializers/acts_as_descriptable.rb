require "#{Rails.root}/lib/acts_as_descriptable/lib/acts_as_descriptable"
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Descriptable)

# require "#{Rails.root}/lib/acts_as_descriptable/lib/acts_as_descriptable"
