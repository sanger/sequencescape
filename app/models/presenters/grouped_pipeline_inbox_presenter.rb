# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

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

    # Register our fields and their respective conditions
    # TODO: Drive some of these directly from the database
    add_field 'Internal ID',    :internal_id
    add_field 'Barcode',        :barcode
    add_field 'Wells',          :wells,          if: :purpose_important?
    add_field 'Plate Purpose',  :plate_purpose,  if: :purpose_important?
    add_field 'Pick To',        :pick_to,        if: :purpose_important?
    add_field 'Next Pipeline',  :next_pipeline,  if: :display_next_pipeline?
    add_field 'Submission',     :submission_id,  if: :group_by_submission?
    add_field 'Study',          :study,          if: :group_by_submission?
    add_field 'Stock Barcode',  :stock_barcode,  if: :show_stock?
    add_field 'Still Required', :still_required, if: :select_partial_requests?
    add_field 'Submitted at',   :submitted_at

    attr_reader :pipeline, :user

    def initialize(pipeline, user, show_held_requests = false)
      @pipeline = pipeline
      @user = user
      @show_held_requests = show_held_requests
    end

    def each_field_header
      valid_fields.each do |field, _method, _condition|
        yield field
      end
    end

    def each_method
      valid_fields.each do |_field, method, _condition|
        yield method
      end
    end

    # Yields a line presenter
    def each_line
      grouped_requests.each_with_index do |request, index|
        group = [request.container_id, request.submission_id]
        yield GroupLinePresenter.new(group, request, index, pipeline, self)
      end
    end

    def field_count
      valid_fields.size
    end

    private

    def grouped_requests
      @request_groups ||= @pipeline.grouped_requests(@show_held_requests)
    end

    def valid_fields
      @valid_fields ||= self.class.fields.select { |_n, _m, c| c.nil? || send(c) }
    end

    def purpose_important?
      pipeline.purpose_information?
    end

    def display_next_pipeline?
      pipeline.display_next_pipeline?
    end

    def select_partial_requests?
      !pipeline.purpose_information?
    end

    def show_stock?
      !pipeline.purpose_information?
    end

    def group_by_submission?
      pipeline.group_by_submission?
    end
  end

  class GroupLinePresenter
    include PipelinesHelper

    attr_reader :group, :request, :index, :pipeline, :inbox
    def initialize(group, request, index, pipeline, inbox)
      @group, @request, @index, @pipeline, @inbox = group, request, index, pipeline, inbox
    end

    def group_id
      group.join(', ')
    end

    def request_group_id
      "request_group_#{group_id.gsub(/[^a-z0-9]+/, '_')}"
    end

    def parent
      @parent ||= Asset.find(group.first)
    end

    def submission_id
      request.submission_id
    end

    def submission
      request.submission
    end

    def submitted_at
      request.submitted_at
    end

    def submission_name
      submission.name if submission_id.present?
    end

    def priority
      request.max_priority
    end

    def each_field
      inbox.each_method do |method|
        yield send(method)
      end
    end

    def internal_id
      parent.id
    end

    def barcode
      parent.sanger_human_barcode
    end

    def wells
      request.request_count
    end

    def plate_purpose
      parent.purpose.name
    end

    def pick_to
      target_purpose_for(request)
    end

    def next_pipeline
      next_pipeline_name_for(request)
    end

    def study
      submission.study_names if submission_id.present?
    end

    def stock_barcode
      parent.source_plate.try(:sanger_human_barcode) || 'Unknown'
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
