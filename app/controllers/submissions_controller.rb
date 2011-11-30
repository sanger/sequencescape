class SubmissionCreater
  ATTRIBUTES = [
    :submission_id,
    :template_id,
    :study_id,
    :project_name,
    :lanes_of_sequencing_required,
    :comments,
    :order_params,
    :asset_group
  ]

  attr_accessor *ATTRIBUTES

  def initialize(user, submission_attributes = {})
    @user = user

    ATTRIBUTES.each do |attribute|
      send("#{attribute}=", submission_attributes[attribute])
    end

  end

  def build_submission!
    raise "NOT IMPLEMENTED YET"
  end

  def find_asset_group
    return nil if asset_group.blank?
    AssetGroup.find(asset_group)
  end

  def order
    @order ||= template.new_order(
      :study       => study,
      :project     => project,
      :user        => @user,
      :asset_group => find_asset_group
    )
  end

  # These parameters should be defined by the submission template (to be renamed
  # order template) the old view code gets them by generating a new instance of
  # Order and then calling Order#input_field_infos.  This is a wrapper around
  # until I can refactor it out.
  def order_parameters
    order.input_field_infos
  end

  def project
    @project ||= Project.find_by_name(@project_name)
  end

  # Creates a new submission and adds an initial order on the submission using
  # the parameters
  def save!
    ActiveRecord::Base.transaction do
      submission = Submission.create!(:user => @user)

      order = template.new_order(
        :study           => study,
        :project         => project,
        :user            => @user,
        :request_options => order_params,
        :submission      => submission,
        :comments        => comments,
        :asset_group     => find_asset_group
      )

      # order.update_attributes()

      order.save!

    end
  end


  # def asset_source_details_from_request_parameters!
  #   # Raise an error if someone tries to do multiple things all at once!
  #   input_choice = [ :asset_group, :asset_ids, :asset_names, :sample_names ].select { |k| not params[k].blank? }
  #   raise InvalidInputException, "No assets found" if input_choice.empty?
  #   raise InvalidInputException, "Cannot handle choosing multiple asset sources" unless input_choice.size == 1

  #   return  case input_choice.first
  #           when :asset_group then { :asset_group => AssetGroup.find(params[:asset_group]) }
  #           when :asset_ids   then { :assets => Asset.find_all_by_id(params[:asset_ids].split).uniq }
  #           when :asset_names then { :assets => find_by_name(Asset, params[:asset_names]) }
  #           when :sample_names
  #             asset_lookup_method = params[:plate_purpose_id].blank? ? :assets_of_request_type_for : :wells_on_specified_plate_purpose_for
  #             { :assets => send(asset_lookup_method, find_sample_by_name_or_sanger_sample_id(params[:sample_names])) }

  #           else raise StandardError, "No way to determine assets for input choice #{input_choice.first.inspect}"
  #           end
  # end
  # private :asset_source_details_from_request_parameters!

  def study
    @study ||= Study.find(@study_id)
  end

  def studies
    @studies ||= @user.interesting_studies
  end

  def submission
    @submission ||= Submission.find(@submission_id)
  end

  # Returns the SubmissionTemplate (OrderTemplate) to be used for this Submission.
  def template
    @template ||= SubmissionTemplate.find(@template_id)
  end

  def templates
    @templates ||= SubmissionTemplate.all
  end

  # Returns an array of all the names of studies associated with the current
  # user.
  def user_projects
    @user_projects ||= @user.sorted_project_names_and_ids.map(&:first)
  end
end




class SubmissionsController < ApplicationController

  def new
    @presenter = SubmissionCreater.new(current_user)
  end

  def create
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    @presenter.save!

    redirect_to :edit
  end


  ###################################################               AJAX ROUTES
  # TODO[sd9]: These AJAX routes could be re-factored
  def project_details
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    render :partial => 'project_details', :layout => false
  end

  def order_parameters
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    render :partial => 'order_parameters', :layout => false
  end

  def study_assets
    @presenter = SubmissionCreater.new(current_user, params[:submission])

    render :partial => 'study_assets', :layout => false
  end
  ##################################################         End of AJAX ROUTES
end

