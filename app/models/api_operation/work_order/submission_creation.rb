# frozen_string_literal: true

# Creates the submission for an operation's work order, as BulkSubmission does
# for a row of a spreadsheet, but reading the payload's work_order section
# (see config/schemas/work-order-schema).
#
# - Submission name: the work order's external_id, which also names the asset
#   group of its orders.
# - User: the user whose login is requested_by.
# - Project: the Sapio project of the cost_code, found or created by
#   ApiOperation::WorkOrder::SapioProjectResolver.
# - Orders: one per study of the requested labware, each with the receptacles of that
#   study; all with the work order's project.
# - Assets: the requested receptacles (ApiOperation::WorkOrder::RequestedReceptacles),
#   each a tube barcode or a "plate barcode:well" combination.
# - Request options: the work order's options with the calculated ones
#   (ApiOperation::WorkOrder::OrderOptions), named as the request options.
#
# ApiOperation::WorkOrder runs it, in the coordinator's transaction.
class ApiOperation::WorkOrder::SubmissionCreation
  include ActiveModel::Validations

  # @param api_operation [ApiOperation] the operation whose work order to submit
  # @param template [SubmissionTemplate] the template of the work order's service
  # @param project [Project, nil] the work order's project, found from its cost code if not given
  # @param requested_receptacles [ApiOperation::WorkOrder::RequestedReceptacles, nil] the work
  #   order's requested receptacles, found from its identifiers if not given
  def initialize(api_operation, template, project: nil, requested_receptacles: nil)
    @work_order = JSON.parse(api_operation.payload).fetch('work_order')
    @template = template
    @project = project
    @requested_receptacles = requested_receptacles ||
      ApiOperation::WorkOrder::RequestedReceptacles.new(@work_order['requested_labware_identifiers'])
  end

  # Builds the submission, as BulkSubmission#process does for each submission of a spreadsheet:
  # the orders for the requested receptacles, then the submission of that order.
  # @return [Array<Hash>] the problems, each with a :pointer and :detail; empty if the submission was built
  def call
    Submission.create!(name: external_id, user: user, orders: orders, priority: priority)
    []
  rescue ApiOperation::Error => e
    [e.to_h]
  rescue Submission::ProjectValidation::Error => e
    [{ pointer: '/work_order/cost_code', detail: "There was an issue with the project: #{e.message}" }]
  rescue ActiveRecord::RecordInvalid => e
    [{ pointer: '/work_order', detail: e.message }]
  end

  private

  def external_id
    @work_order['external_id']
  end

  def user
    @user ||= User.find_by(login: @work_order['requested_by']) ||
      raise(ApiOperation::Error.new('/work_order/requested_by',
                                    "Cannot find user #{@work_order['requested_by'].inspect}"))
  end

  def cost_code
    @work_order['cost_code'].to_s.strip
  end

  def project
    @project ||= ApiOperation::WorkOrder::SapioProjectResolver.new(cost_code).find_or_create
  rescue ActiveRecord::RecordInvalid => e
    raise ApiOperation::Error.new('/work_order/cost_code', e.message)
  end

  def receptacles
    @requested_receptacles.receptacles
  end

  # The work order's options with those calculated for the template.
  def order_options
    @order_options ||= ApiOperation::WorkOrder::OrderOptions.new(
      @template, @work_order['options'] || {}, @requested_receptacles
    )
  end

  def orders
    @requested_receptacles.receptacles_by_study.map { |study, study_receptacles| order(study, study_receptacles) }
  end

  def order(study, study_receptacles)
    add_study_to_assets(study_receptacles, study)

    @template.new_order(order_attributes(study, study_receptacles)).tap do |new_order|
      new_order.request_type_multiplier do |multiplexed_request_type_id|
        new_order.request_options[:multiplier][multiplexed_request_type_id] = order_options.number_of_lanes
      end
    end
  end

  def order_attributes(study, study_receptacles)
    {
      study: study, project: project, user: user, comments: order_options.comments,
      request_options: order_options.request_options, pre_cap_group: order_options.pre_capture_group,
      asset_group_name: external_id, assets: study_receptacles
    }
  end

  def add_study_to_assets(assets, study)
    assets.flat_map(&:samples).uniq.each { |sample| sample.studies << study unless sample.studies.include?(study) }
  end

  def priority
    order_options.priority
  end
end
