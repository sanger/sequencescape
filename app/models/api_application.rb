class ApiApplication < ApplicationRecord
  include SharedBehaviour::Named

  validates_presence_of :name, :key, :contact, :privilege

  validates_inclusion_of :privilege, in: %w[full tag_plates]

  validates_length_of :key, minimum: 20

  before_validation :generate_new_api_key, unless: :key?

  def generate_new_api_key
    self.key = SecureRandom.base64(configatron.fetch('api_key_length') || 20)
  end

  def generate_new_api_key!
    generate_new_api_key
    save!
  end
end
