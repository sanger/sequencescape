module Presenters
  # The {Batch} show page in the {BatchesController} has a side menu which displays
  # a variety of options depending on properties of the batch. The {BatchSubmenuPresenter}
  # encapsulates the logic which was previously in the view itself.
  class BatchSubmenuPresenter
    attr_reader :options

    # Provide access to url_for and other Rails URL helpers {ActionDispatch::Routing::UrlFor}
    # Included directly as Rails.application.routes.url_helpers itself generates a
    # new module every time it is called
    # @see https://api.rubyonrails.org/v5.1/classes/ActionDispatch/Routing/UrlFor.html
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TextHelper

    private

    def set_defaults(defaults)
      @defaults = defaults
    end

    def initialize(current_user, batch)
      @current_user = current_user
      @batch = batch
      @pipeline = @batch.pipeline

      set_defaults(controller: :batches, id: @batch.id, only_path: true)
    end

    def build_submenu
      add_submenu_option 'View summary', controller: :pipelines, action: :summary
      add_submenu_option pluralize(@batch.comments.size, 'comment'), batch_comments_path(@batch)
      load_pipeline_options
      add_submenu_option 'NPG run data', "#{configatron.run_data_by_batch_id_url}#{@batch.id}"
    end

    def is_manager?
      # The logic below is strange. It seems to block actions from owners who aren't also lab managers
      # however still allows those without any role access.
      !@current_user.is_owner? || @current_user.is_manager?
    end

    def is_multiplexed?
      @batch.multiplexed?
    end

    def cherrypicking?
      @pipeline.is_a?(CherrypickingPipeline)
    end

    def genotyping?
      @pipeline.genotyping?
    end

    def pacbio?
      @pipeline.is_a?(PacBioSequencingPipeline)
    end

    def not_sequencing?
      !@pipeline.is_a?(SequencingPipeline)
    end

    def can_create_stock_assets?
      @batch.pipeline.can_create_stock_assets?
    end

    def pacbio_sample_pipeline?
      @pipeline.is_a?(PacBioSamplePrepPipeline)
    end

    def tube_layout_not_verified?
      @batch.has_limit? and !@batch.has_event('Tube layout verified')
    end

    def has_plate_labels?
      [cherrypicking?, genotyping?, pacbio?, pacbio_sample_pipeline?].any?
    end

    def has_tube_labels?
      @batch.requests.any? { |r| r.target_asset.respond_to?(:human_barcode) }
    end

    def has_stock_labels?
      [not_sequencing?, can_create_stock_assets?, !is_multiplexed?].all?
    end

    def load_pipeline_options
      add_submenu_option 'Edit batch', edit_batch_path(@batch) if is_manager?

      # Printing of labels is enabled for anybody
      add_submenu_option 'Print labels', :print_labels if has_tube_labels?
      add_submenu_option 'Print pool label', :print_multiplex_labels if is_multiplexed?
      add_submenu_option 'Print stock pool label', :print_stock_multiplex_labels if is_multiplexed?
      add_submenu_option 'Print plate labels', :print_plate_labels if has_plate_labels?
      add_submenu_option 'Print stock labels', :print_stock_labels if has_stock_labels?

      # Other options are enabled only for managers
      if is_manager?
        add_submenu_option 'Create stock tubes', new_batch_stock_asset_path(@batch) if can_create_stock_assets?
        add_submenu_option 'Print sample prep worksheet', :sample_prep_worksheet if pacbio_sample_pipeline?

        if @pipeline.prints_a_worksheet_per_task? and !pacbio_sample_pipeline?
          @tasks.each do |task|
            add_submenu_option "Print worksheet for #{task.name}", action: :print, task_id: task.id
          end
        else
          add_submenu_option 'Print worksheet', :print
        end

        add_submenu_option 'Verify tube layout', :verify if tube_layout_not_verified?
      end
    end

    public

    def add_submenu_option(text, action_params)
      @options ||= Array.new

      # If it is a string, it will be an url
      unless action_params.is_a?(String)
        # If it is a symbol, it will be the action
        # If not, it will be a Hash with the new content (controller, action, ...)
        if (action_params.is_a?(Symbol))
          action_params = { action: action_params }
        end
        actionConfig = @defaults.dup
        action_params.each_pair do |key, value|
          actionConfig[key] = value
        end
        action_params = url_for(actionConfig)
      end
      @options += [{ label: text, url: action_params }]
    end

    def each_option
      build_submenu if @options.nil?
      @options.each do |option|
        yield option
      end
    end
  end
end
