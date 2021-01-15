class UsersController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :find_user, except: [:index]
  before_action :validate_user, except: %i[index projects study_reports]

  def index
    @users = User.all
  end

  def show
    @printer_list = BarcodePrinter.alphabetical.where(barcode_printer_type: BarcodePrinterType96Plate.all)

    begin
      label_template = LabelPrinter::PmbClient.get_label_template_by_name(configatron.swipecard_pmb_template)
                                              .fetch('data')
                                              .first
      @label_template_id ||= label_template['id']
    rescue LabelPrinter::PmbException => e
      @label_template_id = nil
      flash.now[:error] = "Print My Barcode: #{e}"
    rescue NoMethodError
      @label_template_id = nil
      flash.now[:error] = 'Wrong PMB Label Template'
    end
  end

  def edit
  end

  def update
    params[:user].delete(:swipecard_code) if params[:user][:swipecard_code].blank?
    @user = User.find(params[:id])
    if @user.id == params[:id].to_i
      @user.update(params[:user])
    end
    if @user.save
      flash[:notice] = 'Profile updated'
    else
      flash[:error] = 'Problem updating profile.'
    end
    redirect_to action: :show, id: @user.id
  end

  def projects
    @projects = Project.for_user(@user).page(params[:page])
  end

  def study_reports
    @study_reports = StudyReport.for_user(@user).page(params[:page]).order(id: :desc)
  end

  private

  def validate_user
    return true if can? :manage, @user

    redirect_to profile_path(current_user),
                alert: "You don't have permission to view or edit that profile: here is yours instead."
  end

  def find_user
    @user = User.find(params[:id])
  end
end
