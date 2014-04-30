class CreateAssetRequest < Request
  def initialize_aliquots
    # set study on aliquot
    asset.try(:aliquots).try(:each) do |aliquot|
      return if aliquot.study_id || aliquot.project_id
      aliquot.update_attributes!(:study_id => self.initial_study_id, :project_id => self.initial_project_id)
    end
  end
  private :initialize_aliquots
  before_save :initialize_aliquots

  # CreateAssetRequests should only be generated for sample tubes, or for wells on
  # stock plates.
  validate :on_valid_asset?
  def on_valid_asset?
    return true if asset.can_be_created?
    errors.add :asset, "should be either a sample tube, or a well on a stock plate."
    false
  end
  private :on_valid_asset?

end
