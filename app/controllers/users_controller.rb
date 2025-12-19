# frozen_string_literal: true
class UsersController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_user
  authorize_resource

  def show
    @page_name = @user.name
    @printer_list = BarcodePrinter.alphabetical.where(barcode_printer_type: BarcodePrinterType96Plate.all).pluck(:name)
  end

  def edit
  end

  def update # rubocop:todo Metrics/AbcSize
    params[:user].delete(:swipecard_code) if params[:user][:swipecard_code].blank?
    @user = User.find(params[:id])
    @user.update(params[:user]) if @user.id == params[:id].to_i
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

  def print_swipecard
    swipecard = params[:swipecard]
    printer = params[:printer]
    if swipecard.strip.present?
      print_swipecard_with_pmb(swipecard, printer)
    else
      flash[:error] = 'Cannot print empty swipecard'
    end
    redirect_to action: :show, id: @user.id
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def print_swipecard_with_pmb(swipecard, printer) # rubocop:todo Metrics/MethodLength
    print_job =
      LabelPrinter::PrintJob.new(
        printer,
        LabelPrinter::Label::Swipecard,
        user_login: @user.login.truncate(10, omission: '..'),
        swipecard: swipecard,
        label_template_name: configatron.swipecard_pmb_template
      )
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        if current_user
          redirect_to profile_path(current_user),
                      alert: "You don't have permission to view or edit that profile: here is yours instead."
        else
          redirect_back_or_to(main_app.root_url, alert: exception.message)
        end
      end
    end
  end
end
