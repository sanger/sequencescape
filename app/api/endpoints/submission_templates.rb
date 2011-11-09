class Endpoints::SubmissionTemplates < Core::Endpoint::Base
  model do

  end

  instance do
    factory(:to => 'submissions', :json => 'submissions') do |request, _|
      ActiveRecord::Base.transaction do
        attributes = ::Io::Submission.map_parameters_to_attributes(request.json)[:order_attributes]
        request.target.create_with_submission!(attributes.merge(:user => request.user)).submission
      end
    end
  end
end
