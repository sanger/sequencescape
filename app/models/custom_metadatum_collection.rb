# frozen_string_literal: true
class CustomMetadatumCollection < ApplicationRecord # rubocop:todo Style/Documentation
  include Uuid::Uuidable

  belongs_to :user
  belongs_to :asset, class_name: 'Labware' # Labware (Used on plates and allowed on tubes but not used)
  has_many :custom_metadata, dependent: :destroy

  def metadata
    custom_metadata.collect(&:to_h).inject(:merge!) || {}
  end

  def metadata=(attributes)
    ActiveRecord::Base.transaction do
      custom_metadata.clear
      attributes.map { |k, v| custom_metadata.build(key: k, value: v) }
    end
  end
end
