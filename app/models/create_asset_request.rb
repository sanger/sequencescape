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


end
