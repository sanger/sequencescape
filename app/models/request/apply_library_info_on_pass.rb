module Request::ApplyLibraryInfoOnPass
  def on_passed
    super
    apply_library_information!
  end

  #
  # Applies the library information to aliquots of
  # the target asset. Library id is used for downstream
  # tracking, and primarily acts as a unique identifier.
  # Note: Automatically saves the aliquots.
  # JG 27/03/2018: We recently switched to applying this information upfront
  # when libraries are started; (library_id gets set on tagging) so this
  # block should shortly be redundant. Once in progress work has trickled
  # through it'll probably be safe to remove
  #
  # @return [IlluminaHtp::Requests] Returns itself
  #
  def apply_library_information!
    target_asset.aliquots.each do |aliquot|
      aliquot.library_id   ||= target_asset.id
      aliquot.library_type ||= library_type
      aliquot.insert_size  ||= insert_size
      aliquot.save! if aliquot.changed?
    end
    self
  end
end
