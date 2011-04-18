class Api::SubmissionsController < Api::BaseController
  
  def types
    respond_to do |format|
      format.json { render :json => Api::Submission.types.to_json }
    end
  end
  
  def create
#    raise Exception.new, params.to_yaml
    @submission = Api::SubmissionIO.new(params[:submission], self.current_user)
    respond_to do |format|
      if @submission.check
        format.json { render :json => @submission.to_json, :status => :created}
      else
        format.json { render :json => @submission.errors, :status => :unprocessable_entity }
      end
    end
  end

end
