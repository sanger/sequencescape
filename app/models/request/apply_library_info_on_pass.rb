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
  #
  # @return [IlluminaHtp::Requests] Returns itself
  #
  def apply_library_information!
    target_asset.aliquots.each do |aliquot|
      aliquot.library      ||= target_asset
      aliquot.library_type ||= library_type
      aliquot.insert_size  ||= insert_size
      aliquot.save!
    end
    self
  end
end
