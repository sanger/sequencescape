# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Api::BaseController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  class_attribute :model_class
  before_action { |controller| Uuid.translate_uuids_to_ids_in_params(controller.params) }
  around_action :wrap_in_transaction, only: [:create, :update, :destroy]

  delegate :render_class, to: :model_class

  #--
  # Exception handling code
  #++
  rescue_from ActiveRecord::RecordInvalid do |exception|
    errors = exception.record.errors.inject(Hash.new { |h, k| h[k] = [] }) do |hash, field_and_error_pair|
      hash.tap { hash[field_and_error_pair.first].push(field_and_error_pair.last) }
    end
    respond_to do |format|
      format.json { render json: render_class.map_attribute_to_json_attribute_in_errors(errors), status: :unprocessable_entity }
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    head(:not_found)
  end

  #--
  # CRUD methods
  #++
  def show
    respond_to do |format|
      format.json { render json: @object.to_json }
    end
  end

  def index
    sort_order = @context_order || { id: :desc }

    results = @context.order(sort_order).paginate(page: params[:page], total_entries: 100000000, per_page: 500)

    respond_to do |format|
      format.json { render json: results }
    end
  end

  def create
    object = render_class.create!(params)
    respond_to do |format|
      format.json { render json: object.to_json, status: :created, location: object }
    end
  end

  def update
    render_class.update_attributes!(@object, params)
    respond_to do |format|
      format.json { head :ok }
    end
  end

  def destroy
    @object.destroy

    respond_to do |format|
      format.json { head :ok }
    end
  end

private

  #--
  # Preparation filters for CRUD methods.
  #++
  def prepare_object
    @object = model_class.find(params[:id])
  end

  def prepare_list_context
    @context = model_class
  end

  def wrap_in_transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  def attributes_for_model_from_parameters
    params[model_class.name.underscore]
  end

  def uuid_to_id
    Uuid.translate_uuids_to_ids_in_params(params)
  end
end
