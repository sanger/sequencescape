# frozen_string_literal: true
# An external application using the V1 API
# Provides an api_key which can be used to authenticate the application,
# as well as contact information should the API change
class ApiApplication < ApplicationRecord
  include SharedBehaviour::Named

  validates :name, :key, :contact, :privilege, presence: true

  validates :privilege, inclusion: { in: %w[full tag_plates] }

  validates :key, length: { minimum: 20 }

  before_validation :generate_new_api_key, unless: :key?

  INTEGRATION_HUB_NAME = 'Integration Hub'

  def integration_hub?
    name == INTEGRATION_HUB_NAME
  end
  
  def generate_new_api_key
    self.key = SecureRandom.base64(configatron.fetch('api_key_length') || 20)
  end

  def generate_new_api_key!
    generate_new_api_key
    save!
  end
end
