# frozen_string_literal: true
class UsersController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_user
  authorize_resource

  def show
    @printer_list = BarcodePrinter.alphabetical.where(barcode_printer_type: BarcodePrinterType96Plate.all).map(&:name)
  end

  def edit; end

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
  
  def print_swipecard_with_pmb(swipecard, printer)
    LabelPrinter::PmbClient.print({ 
      printer_name: printer,
      label_template_name: configatron.swipecard_pmb_template,
      labels: [ 
        left_text: @user.login.truncate(10, omission: '..'),
        barcode: swipecard,
        label_name: 'main'
      ]
    })
    rescue StandardError => e
      flash[:error] = "There has been an error printing your swipecard: #{e}"
    else
      flash[:notice] = "Swipecard has been sent to print at #{printer}"
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        if current_user
          redirect_to profile_path(current_user),
                      alert: "You don't have permission to view or edit that profile: here is yours instead."
        else
          redirect_back fallback_location: main_app.root_url, alert: exception.message
        end
      end
    end
  end
end
