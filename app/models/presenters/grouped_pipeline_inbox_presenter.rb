# frozen_string_literal: true
module Presenters
  class GroupedPipelineInboxPresenter
    class << self
      def fields
        @fields ||= []
      end

      def add_field(name, method, options = {})
        fields << [name, method, options[:if]]
      end
    end

    ALL_STATES = %w[pending hold].freeze
    VISIBLE_STATES = 'pending'

    # Register our fields and their respective conditions
    add_field 'Internal ID', :internal_id
    add_field 'Barcode', :barcode
    add_field 'Wells', :well_count, if: :purpose_important?
    add_field 'Plate Purpose', :plate_purpose, if: :purpose_important?
    add_field 'Pick To', :pick_to
    add_field 'Submission', :submission_id, if: :group_by_submission?
    add_field 'Study', :study, if: :group_by_submission?
    add_field 'Stock Barcode', :stock_barcode, if: :show_stock?
    add_field 'Still Required', :still_required, if: :select_partial_requests?
    add_field 'Submitted at', :submitted_at

    attr_reader :pipeline, :user

    delegate :group_by_parent?, :group_by_submission?, :purpose_information?, to: :pipeline

    def initialize(pipeline, user, show_held_requests = false)
      @pipeline = pipeline
      @user = user
      @show_held_requests = show_held_requests

      # We shouldn't trigger this, as we explicitly detect the group by status
      return if pipeline.group_by_parent?
        raise "Pipeline #{pipeline.name} is incompatible with GroupedPipelineInboxPresenter"
      
    end

    def requests_waiting
      @pipeline.requests.unbatched.where(state: ALL_STATES).count
    end

    def purpose_important?
      purpose_information?
    end

    def each_field_header
      valid_fields.each { |field, _method, _condition| yield field }
    end

    def each_method
      valid_fields.each { |_field, method, _condition| yield method }
    end

    # Yields a line presenter
    def each_line
      grouped_requests.each_with_index do |request, index|
        group = [request.labware_id, request.submission_id]
        yield GroupLinePresenter.new(group, request, index, pipeline, self)
      end
    end

    def field_count
      valid_fields.size
    end

    private

    def states
      @show_held_requests ? ALL_STATES : VISIBLE_STATES
    end

    def grouped_requests
      @request_groups ||=
        @pipeline
          .requests
          .where(state: states)
          .asset_on_labware
          .unbatched
          .send(@pipeline.inbox_eager_loading)
          .select('requests.*', 'count(DISTINCT requests.id) AS well_count', 'MAX(requests.priority) AS priority')
          .group(grouping_attributes)
    end

    def grouping_attributes
      group_by_submission? ? %w[labware_id submission_id] : 'labware_id'
    end

    def valid_fields
      @valid_fields ||= self.class.fields.select { |_n, _m, c| c.nil? || send(c) }
    end

    def select_partial_requests?
      !purpose_information?
    end

    def show_stock?
      !purpose_information?
    end
  end

  class GroupLinePresenter
    include PipelinesHelper

    attr_reader :group, :request, :index, :pipeline, :inbox

    delegate :submission_id, :submission, :submitted_at, :priority, :well_count, to: :request

    def initialize(group, request, index, pipeline, inbox)
      @group = group
      @request = request
      @index = index
      @pipeline = pipeline
      @inbox = inbox
    end

    def group_id
      group.join(', ')
    end

    def request_group_id
      "request_group_#{group_id.gsub(/[^a-z0-9]+/, '_')}"
    end

    def parent
      @parent ||= request.asset.labware || Labware.find(group.first)
    end

    def submission_name
      submission.name if submission_id.present?
    end

    def each_field
      inbox.each_method { |method| yield send(method) }
    end

    def internal_id
      parent.id
    end

    def barcode
      parent.human_barcode
    end

    def plate_purpose
      parent.purpose&.name
    end

    def pick_to
      target_purpose_for(request)
    end

    def study
      submission.study_names if submission_id.present?
    end

    def stock_barcode
      parent.source_plate.try(:human_barcode) || 'Unknown'
    end

    def still_required
      wells / parent.height
    end

    # Gates

    def groupless?
      yield if group.blank?
    end

    def standard_fields?
      yield unless parent.nil?
    end

    def parentless?
      yield if parent.nil?
    end
  end
end
