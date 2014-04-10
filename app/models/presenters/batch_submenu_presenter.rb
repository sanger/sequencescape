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
      build_submenu
    end

    def build_submenu
      add_submenu_option "View summary", { :controller => :pipelines, :action => :summary }
      add_submenu_option pluralize(@batch.comments.size, "comment" ), batch_comments_path(@batch)
      unless @current_user.is_owner? && ! @current_user.is_manager?
        add_submenu_option "Edit batch", edit_batch_path(@batch)
        load_pipeline_options
      end
      add_submenu_option "NPG run data", "#{configatron.run_data_by_batch_id_url}#{@batch.id}"
      add_submenu_option "SybrGreen images", "#{configatron.sybr_green_images_url}#{@batch.id}"
    end

    def load_pipeline_options
      if  @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
        add_submenu_option "Print labels", :print_labels
      elsif @batch.multiplexed?
        add_submenu_option "Print pool label", :print_multiplex_labels
        add_submenu_option "Print labels" ,  :print_labels
        add_submenu_option "Print stock pool label" , :print_stock_multiplex_labels
      elsif @pipeline.is_a?(CherrypickingPipeline) || @pipeline.is_a?(GenotypingPipeline) || @pipeline.is_a?(PacBioSequencingPipeline)
        add_submenu_option "Print plate labels" , :print_plate_labels
      elsif (!@pipeline.is_a?(SequencingPipeline))
        if @batch.pipeline.can_create_stock_assets?
          add_submenu_option "Print stock labels" , :print_stock_labels
        end
        add_submenu_option "Print labels" , :print_labels
      end
      unless @pipeline.is_a?(SequencingPipeline)
        add_submenu_option "Vol' & Conc'", :edit_volume_and_concentration
      end
      if @batch.pipeline.can_create_stock_assets?
        add_submenu_option "Create stock tubes"  , :new_stock_assets
      end

      if @pipeline.is_a?(PacBioSamplePrepPipeline)
        add_submenu_option "Print worksheet" , :sample_prep_worksheet
      elsif @pipeline.prints_a_worksheet_per_task?
        @tasks.each do |task|
          add_submenu_option "Print worksheet for #{task.name}" , {:action => :print, :task_id => task.id}
        end
      else
        add_submenu_option "Print worksheet" , :print
      end

      if @batch.has_limit?
        unless @batch.has_event("Tube layout verified")
          add_submenu_option "Verify tube layout" , :verify
        end
      end

      if @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
        add_submenu_option "Batch Report", :pulldown_batch_report
      end
    end

    public

    def add_submenu_option(text, actionParams)
      if @options == nil
        @options = Array.new
      end

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

    def to_s
      @options.each {|option| "#{option},"}
    end

  end
end