# frozen_string_literal: true

module Presenters
  # The {Batch} show page in the {BatchesController} has a side menu which displays
  # a variety of options depending on properties of the batch. The {BatchSubmenuPresenter}
  # encapsulates the logic which was previously in the view itself.
  class BatchSubmenuPresenter
    attr_reader :options, :ability, :pipeline, :batch

    # Provide access to url_for and other Rails URL helpers {ActionDispatch::Routing::UrlFor}
    # Included directly as Rails.application.routes.url_helpers itself generates a
    # new module every time it is called
    # @see https://api.rubyonrails.org/v5.1/classes/ActionDispatch/Routing/UrlFor.html
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TextHelper

    delegate :sequencing?, to: :pipeline

    def initialize(current_user, batch)
      @current_user = current_user
      @ability = Ability.new(current_user)
      @batch = batch
      @pipeline = @batch.pipeline

      @defaults = { controller: :batches, id: @batch.id, only_path: true }
    end

    def add_submenu_option(text, action_params)
      @options ||= []

      # If it is a string, it will be an url
      unless action_params.is_a?(String)
        # If it is a symbol, it will be the action
        # If not, it will be a Hash with the new content (controller, action, ...)
        action_params = { action: action_params } if action_params.is_a?(Symbol)
        action_config = @defaults.dup
        action_params.each_pair { |key, value| action_config[key] = value }
        action_params = url_for(action_config)
      end
      @options += [{ label: text, url: action_params }]
    end

    def each_option(&)
      build_submenu if @options.nil?
      @options.each(&)
    end

    private

    def can?(permission, object = @batch)
      ability.can? permission, object
    end

    def build_submenu
      add_submenu_option 'View summary', controller: :pipelines, action: :summary
      add_submenu_option pluralize(@batch.comments.size, 'comment'), batch_comments_path(@batch)
      load_pipeline_options
      add_submenu_option 'NPG run data', "#{configatron.run_data_by_batch_id_url}#{@batch.id}"
      return unless aviti_requests?
      add_submenu_option 'Download Sample Sheet', id: @batch.id, controller: :batches, action: :generate_sample_sheet
    end

    # This is used to determine if the batch is related to Element Aviti pipeline.
    def aviti_requests?
      @batch.requests.any? { ElementAvitiSequencingRequest }
    end

    def cherrypicking?
      @pipeline.is_a?(CherrypickingPipeline)
    end

    def worksheet?
      @pipeline.batch_worksheet.present?
    end

    def tube_layout_not_verified?
      @batch.has_limit? and !@batch.has_event('Tube layout verified')
    end

    def plate_labels?
      cherrypicking?
    end

    def load_pipeline_options
      add_submenu_option 'Edit batch', edit_batch_path(@batch) if can? :edit

      # Printing of labels is enabled for anybody
      add_submenu_option 'Print labels', :print_labels
      add_submenu_option 'Print plate labels', :print_plate_labels if plate_labels?

      add_submenu_option 'Print worksheet', :print if worksheet? && can?(:print)

      add_submenu_option 'Verify tube layout', :verify if tube_layout_not_verified? && can?(:verify)
    end
  end
end
