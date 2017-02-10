# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class SequenomController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  EmptyBarcode = Class.new(StandardError)

  # An instance of this class does the work of updating a Plate with the step performed.
  class SequenomStep
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def update_plate(plate, user)
      plate.events.create!(message: I18n.t('sequenom.events.message', step: name), created_by: user.login)
      yield(self)
    end
  end

  # Here are all of the steps that can be performed
  STEPS = ['PCR Mix', 'SAP Mix', 'IPLEX Mix', 'HPLC Water'].map { |name| SequenomStep.new(name) }
  class << STEPS
    def for(step_name)
      find { |step| step.name == step_name } or raise "Cannot find the Sequenom step '#{step_name}'"
    end
  end

  before_action :login_required
  before_action :find_plate_from_id, only: [:show, :update]

  def index
    # Do nothing, fall through to the view
  end

  def search
    redirect_to sequenom_plate_path(@plate)
  end

  def show
    # Do nothing as @plate is setup by the before filter, fall through to the view
  end

  def update
    ActiveRecord::Base.transaction do
      STEPS.for(params[:sequenom_step]).update_plate(@plate, @user) do |step|
        flash[:notice] = I18n.t(
          'sequenom.notices.step_completed',
          step: step.name, barcode: @plate.ean13_barcode, human_barcode: @plate.sanger_human_barcode
        )
      end
    end
    redirect_to sequenom_plate_path(@plate)
  end

  # Although this might seem stupid this actually enables us to use different filters
  # around this action from the #update action.  We simply need to ensure that @user
  # and @plate are setup before we get to the action code.
  alias_method(:quick_update, :update)

private

  def find_plate_from_id
    @plate = Plate.find(params[:id])
  rescue ActiveRecord::RecordNotFound => exception
    flash[:error] = I18n.t('sequenom.errors.plate.not_found_by_id')
    redirect_to sequenom_root_path
  end

  # Defines a filter method that will lookup an instance of the specified model class, assigning
  # an instance variable or redirecting to the sequenom_root_path on error.  The block passed
  # should take two parameters (the barcode and the human version of that barcode) and return the
  # value that can be used by +model_class.find_by_barcode+.  +filter_options+ are exactly as
  # would be specified for a +before_action+.
  def self.define_find_from_barcode_filter(model_class, filter_options, &block)
    name                        = model_class.name.underscore
    filter_name                 = :"find_#{ name }_from_barcode"
    rescue_exception_for_filter = :"rescue_#{ filter_name }"

    define_method(filter_name) do
      begin
        barcode = params[:"#{ name }_barcode"]
        raise EmptyBarcode, "The #{name} barcode appears to be empty" if barcode.blank?
        human_barcode = Barcode.barcode_to_human!(barcode, model_class.prefix)
        object = model_class.find_by(barcode: block.call(barcode, human_barcode))
        raise ActiveRecord::RecordNotFound, "Could not find a #{name} with barcode #{barcode}" if object.nil?
        instance_variable_set("@#{name}", object)
      rescue StandardError => exception
        send(rescue_exception_for_filter, exception, barcode, human_barcode)
      end
    end
    define_method(rescue_exception_for_filter) do |exception, barcode, human_barcode|
      case
      when ActiveRecord::RecordNotFound === exception
        flash[:error] = I18n.t("sequenom.errors.#{name}.not_found_by_barcode", barcode: barcode, human_barcode: human_barcode)
        redirect_to sequenom_root_path

      when Barcode::InvalidBarcode === exception
        flash[:error] = I18n.t("sequenom.errors.#{name}.invalid_barcode", barcode: barcode, human_barcode: human_barcode)
        redirect_to sequenom_root_path

      when EmptyBarcode === exception
        flash[:error] = I18n.t("sequenom.errors.#{name}.empty_barcode")
        redirect_to sequenom_root_path

      else
        flash[:error] = I18n.t("sequenom.errors.#{name}.unknown")
        redirect_to sequenom_root_path
      end
    end

    before_action(filter_name, filter_options)
  end

  define_find_from_barcode_filter(User,  only: [:update, :quick_update]) { |_barcode, human_barcode| human_barcode }
  define_find_from_barcode_filter(Plate, only: [:search, :quick_update]) { |barcode, _human_barcode| Barcode.number_to_human(barcode) }

  # Handle the case where ActiveRecord::RecordNotFound is raised when looking for a Plate by
  # physically creating the Plate in the database!
  def rescue_find_plate_from_barcode_with_create(exception, barcode, human_barcode)
    rescue_find_plate_from_barcode_without_create(exception, barcode, human_barcode) unless ActiveRecord::RecordNotFound === exception
    @plate = Plate.create!(barcode: Barcode.number_to_human(barcode))
  end
  alias_method_chain(:rescue_find_plate_from_barcode, :create)
end
