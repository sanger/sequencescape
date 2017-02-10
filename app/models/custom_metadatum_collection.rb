class CustomMetadatumCollection < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :user
  belongs_to :asset
  has_many :custom_metadata, dependent: :destroy

  validates_presence_of :asset_id, :user_id

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
