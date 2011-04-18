# This class acts slightly differently from other API classes to hide 
# the internals of Submissions and request types
class Api::SubmissionIO
  attr :params, :user
  attr_accessor :errors
  
  def initialize(params, user)
    if params.nil?
      raise Exception.new, "params not assigned"
    end
    
    if user.nil?
      raise Exception.new, "user not assigned"
    end

    @params = params
    @user   = user
  end

  def to_json
    if @errors
      @errors.to_json
    else
      # TODO: Clean up
      "Submission created".to_json
    end
  end
  
  def self.types
    SubmissionTemplate.all.map { |t| t.name}
  end
  
  # Check the submission and create sequencescape submission
  def check
    study   = ::Study.find(@params[:study_id])
    project = ::Project.find(@params[:project_id])
    assets = ::SampleTube.find(@params[:sample_tubes])
    template = ::SubmissionTemplae.find_by_name(:@params[:type])
    comments = self.params[:comments]
    request_options = {}
    if self.params[:number_of_lanes]
      request_options[:multiplier] = @params[:number_of_lanes]
    end
    
    begin
      submission = ::Submission.build(template, study, project, ::Submission::Workflow.find(1), @user, assets, 
                      samples = [],  request_type_ids, request_options, 
                      comments)
      if submission.new_record?
        return false
      end
    rescue QuotaException => quota_exception
      @errors =  quota_exception.message
      return false
    end
    true
  end

end
