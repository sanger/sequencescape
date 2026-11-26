# frozen_string_literal: true

# Will fetch study information for a study name
class UatActions::StudyInformation < UatActions
  self.title = 'Study information'
  self.description = 'Get study information for a study name.'
  self.category = :setup_and_test

  form_field :study_name, :text_field, label: 'Study Name', help: 'Fetches basic information for a study name.'

  validates :study_name, presence: { message: 'needs a value' }
  validates :study, presence: { message: 'could not be found' }

  def self.default
    new
  end

  def perform
    report[:study_name] = study_name
    return false if study.blank?

    report[:study_uuid] = study.uuid
    true
  end

  private

  def study
    @study = Study.find_by(name: study_name.strip) unless instance_variable_defined?(:@study)
    @study
  end
end
