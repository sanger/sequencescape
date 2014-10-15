class ApiApplication < ActiveRecord::Base

  validates_presence_of :name, :key, :contact, :privilege

  validates_inclusion_of :privilege, :in => ['full','tag_plates']


end
