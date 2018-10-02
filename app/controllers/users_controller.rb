
class UsersController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :validate_user, except: [:index, :projects, :study_reports]
  before_action :find_user, except: [:index]

  def index
    @users = User.all
  end

  def show
    barcode_printers = BarcodePrinter.alphabetical.includes(:barcode_printer_type)
    @printer_list = barcode_printers.select { |printer| printer.barcode_printer_type.name == '96 Well Plate' }
    begin
      label_template = LabelPrinter::PmbClient.get_label_template_by_name('swipecard_barcode_big_5').fetch('data').first
      @label_template_id ||= label_template['id']
    rescue LabelPrinter::PmbException => e
      @label_template_id = nil
      flash[:error] = "Print My Barcode: #{e}"
    rescue NoMethodError
      @label_template_id = nil
      flash[:error] = 'Wrong PMB Label Template'
    end
  end

  def edit
  end

  def update
    params[:user].delete(:swipecard_code) if params[:user][:swipecard_code].blank?
    @user = User.find(params[:id])
    if @user.id == params[:id].to_i
      @user.update_attributes(params[:user])
    end
    if @user.save
      flash[:notice] = 'Profile updated'
    else
      flash[:error] = 'Problem updating profile.'
    end
    redirect_to action: :show, id: @user.id
  end

  def projects
    @projects = @user.projects.page(params[:page])
  end

  def study_reports
    @study_reports = StudyReport.for_user(@user).page(params[:page]).order(id: :desc)
  end

  private

  def validate_user
    if current_user.administrator? || current_user.id == params[:id].to_i
      true
    else
      flash[:error] = "You don't have permission to view or edit that profile: here is yours instead."
      redirect_to action: :show, id: current_user.id
    end
  end

  def find_user
    @user = User.find(params[:id])
  end
end
