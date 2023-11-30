# frozen_string_literal: true
class ReRequestSubmission < Order
  include Submission::LinearRequestGraph
  include Submission::Crossable

  def asset_applicable_to_type?(_request_type, _asset)
    true
  end
  private :asset_applicable_to_type?
end
