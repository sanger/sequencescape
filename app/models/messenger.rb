# frozen_string_literal: true
# Messengers handle passing a target into a message template
# for rendering warehouse messages
class Messenger < ApplicationRecord
  belongs_to :target, ->(messenger) { includes(messenger.render_class.includes) }, polymorphic: true
  validates :target, :root, :template, presence: true
  broadcast_with_warren

  def render_class
    "Api::Messages::#{template}".constantize
  end

  def routing_key
    "message.#{root}.#{id}"
  end

  def as_json(_options = {})
    message = render_class.to_hash(target)
    Rails.logger.info("Publishing message: #{message}")
    { root => process_receptacles(message), 'lims' => configatron.amqp.lims_id! }
  end

  # Processes the message for receptacle targets, setting labware type if applicable.
  # @param message [Hash] The message to process.
  # @return [Hash] The processed message.
  def process_receptacles(message)
    return message unless receptacle_target?

    asset_type = fetch_asset_type
    message['labware_type'] = 'library_plate_well' if library_plate?(asset_type)
    message
  end

  def template
    # Replace IO with Io to match the class name
    # This is a consequence of the zeitwerk renaming for the message modules from IO to Io
    # This ensures that the correct class is loaded for historical messages
    read_attribute(:template).gsub(/IO$/, 'Io')
  end

  def resend
    Warren.handler << Warren::Message::Short.new(self)
  end

  private

  # Checks if the target type is 'Receptacle'.
  # @return [Boolean] True if target type is 'Receptacle', false otherwise.
  def receptacle_target?
    target_type == 'Receptacle'
  end

  # Fetches the asset type for the current target.
  # @return [String, nil] The asset type or nil if not found.
  def fetch_asset_type
    SampleManifestAsset.find_by(asset_id: target_id)&.sample_manifest&.asset_type
  end

  # Determines if the asset type is a library plate.
  # @param asset_type [String, nil] The asset type to check.
  # @return [Boolean] True if asset type is 'library_plate', false otherwise.
  def library_plate?(asset_type)
    asset_type.present? && asset_type == 'library_plate'
  end
end
