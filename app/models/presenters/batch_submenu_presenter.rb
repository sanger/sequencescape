module Presenters
  class BatchSubmenuPresenter
    attr_reader :options
    include ActionController::UrlWriter
    include ActionView::Helpers::TextHelper

    private
    def set_defaults(defaults)
      @defaults=defaults
    end

    def initialize(current_user, batch)
      @current_user = current_user
      @batch = batch
      @pipeline = @batch.pipeline

      set_defaults({:controller => :batches, :id => @batch.id, :only_path => true})
    end

    def build_submenu
      add_submenu_option "View summary", { :controller => :pipelines, :action => :summary }
      add_submenu_option pluralize(@batch.comments.size, "comment" ), batch_comments_path(@batch)
      load_pipeline_options
      add_submenu_option "NPG run data", "#{configatron.run_data_by_batch_id_url}#{@batch.id}"
      add_submenu_option "SybrGreen images", "#{configatron.sybr_green_images_url}#{@batch.id}"
    end

    def load_pipeline_options
      # Conditions to check in order to display the pipeline options
      cond_is_manager = !@current_user.is_owner? || @current_user.is_manager?
      cond_is_pulldown_pipeline= @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
      cond_is_batch_multiplexed = @batch.multiplexed?
      cond_is_cherrypicking_pipeline= @pipeline.is_a?(CherrypickingPipeline)
      cond_is_genotyping_pipeline= @pipeline.is_a?(GenotypingPipeline)
      cond_is_pacbio_pipeline= @pipeline.is_a?(PacBioSequencingPipeline)
      cond_not_seq_pipeline = !@pipeline.is_a?(SequencingPipeline)
      cond_pipeline_can_create_stock_assets =  @batch.pipeline.can_create_stock_assets?
      cond_is_pacbio_sample_pipeline =  @pipeline.is_a?(PacBioSamplePrepPipeline)
      cond_tube_layout_not_verified = @batch.has_limit? and !@batch.has_event("Tube layout verified")

      add_submenu_option "Edit batch", edit_batch_path(@batch) if cond_is_manager

      # Printing of labels is enabled for anybody
      add_submenu_option "Print labels", :print_labels if cond_is_pulldown_pipeline
      add_submenu_option "Print pool label", :print_multiplex_labels if cond_is_batch_multiplexed
      add_submenu_option "Print labels" ,  :print_labels if cond_is_batch_multiplexed
      add_submenu_option "Print stock pool label" , :print_stock_multiplex_labels if cond_is_batch_multiplexed
      add_submenu_option "Print plate labels" , :print_plate_labels if [
          cond_is_cherrypicking_pipeline,
          cond_is_genotyping_pipeline,
          cond_is_pacbio_pipeline ].any?
      add_submenu_option "Print stock labels" , :print_stock_labels if [
        cond_not_seq_pipeline,
        cond_pipeline_can_create_stock_assets].all?
      add_submenu_option "Print labels" , :print_labels if cond_not_seq_pipeline

      # Other options are enabled only for managers
      add_submenu_option "Vol' & Conc'", :edit_volume_and_concentration if [cond_not_seq_pipeline, cond_is_manager].all?
      add_submenu_option "Create stock tubes"  , :new_stock_assets if [cond_pipeline_can_create_stock_assets, cond_is_manager].all?
      add_submenu_option "Print worksheet" , :sample_prep_worksheet if [cond_is_pacbio_sample_pipeline, cond_is_manager].all?

      if @pipeline.prints_a_worksheet_per_task? and !cond_is_pacbio_sample_pipeline
        @tasks.each do |task|
          add_submenu_option "Print worksheet for #{task.name}" , {:action => :print, :task_id => task.id} if cond_is_manager
        end
      else
        add_submenu_option "Print worksheet" , :print if cond_is_manager
      end

      add_submenu_option "Verify tube layout" , :verify if [cond_tube_layout_not_verified, cond_is_manager].all?
      add_submenu_option "Batch Report", :pulldown_batch_report if [cond_is_pulldown_pipeline, cond_is_manager].all?
    end

    public

    def add_submenu_option(text, actionParams)
      @options ||= Array.new

      # If it is a string, it will be an url
      unless actionParams.is_a?(String)
        # If it is a symbol, it will be the action
        # If not, it will be a Hash with the new content (controller, action, ...)
        if (actionParams.is_a?(Symbol))
          actionParams = { :action => actionParams }
        end
        actionConfig = @defaults.dup
        actionParams.each_pair do |key, value|
          actionConfig[key] = value
        end
        actionParams = url_for(actionConfig)
      end
      @options += [{:label => text, :url =>  actionParams}]
    end

    def each_option
      build_submenu if @options.nil?
      @options.each do |option|
        yield option
      end
    end

  end
end
