class ReRequestSubmission < Order # rubocop:todo Style/Documentation
  include Submission::LinearRequestGraph
  include Submission::Crossable

  def asset_applicable_to_type?(_request_type, _asset)
    true
  end
  private :asset_applicable_to_type?
end
