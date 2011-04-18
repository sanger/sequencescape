require 'acts_as_descriptable'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Descriptable)

require File.dirname(__FILE__) + '/lib/acts_as_descriptable'
