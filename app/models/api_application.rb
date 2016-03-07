#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ApiApplication < ActiveRecord::Base

  validates_presence_of :name, :key, :contact, :privilege

  validates_inclusion_of :privilege, :in => ['full','tag_plates']

  validates_length_of :key, :minimum=>20

  before_validation :generate_new_api_key, :unless => :key?

  def generate_new_api_key
    self.key = SecureRandom.base64(configatron.fetch('api_key_length')||20)
  end

  def generate_new_api_key!
    generate_new_api_key
    save!
  end

end
