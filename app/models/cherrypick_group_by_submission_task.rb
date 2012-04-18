class CherrypickGroupBySubmissionTask < Task
  include Cherrypick::Task::PickHelpers
  include Tasks::PlatePurposeBehavior

  class CherrypickGroupBySubmissionData < Task::RenderElement
    alias_attribute :well, :asset

    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && CherrypickGroupBySubmissionData.new(request)
  end

  def partial
    "cherrypick_group_by_submission_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_cherrypick_group_by_submission_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_cherrypick_group_by_submission_task(self, params)
  end

  def submission_ids_of_requests(requests)
    requests.map{ |request| request.submission_id }.uniq
  end

  def sort_requests_by_submission_id(requests, submission_id)
     requests.select{ |request| request.submission_id == submission_id }.sort{ |a,b| a.submission_id <=> b.submission_id }
  end

  def sort_requests_grouped_by_submission_by_asset_map_id(sorted_requests)
    sorted_requests.map{ |requests| requests.sort{ |a,b| a.asset.map_id <=> b.asset.map_id } }
  end

  def group_requests_by_submission_id(requests)
    sorted_requests = submission_ids_of_requests(requests).map do |submission_id|
      sort_requests_by_submission_id(requests, submission_id)
    end
  end

  def sort_grouped_requests_by_submission_id(requests)
    sort_requests_grouped_by_submission_by_asset_map_id(group_requests_by_submission_id(requests)).flatten
  end
  
  def valid_params?(options = {})
    return false unless ["nano_grams", "nano_grams_per_micro_litre","micro_litre"].include?(options[:cherrypick][:action])
    if options[:cherrypick][:action] == "nano_grams"
      [options[:minimum_volume], options[:maximum_volume], options[:total_nano_grams]].each do |input_value|
        return false unless valid_float_param?(input_value) 
      end
      return false if options[:minimum_volume].to_f > options[:maximum_volume].to_f
    elsif options[:cherrypick][:action] == "nano_grams_per_micro_litre"
      [options[:volume_required], options[:concentration_required]].each do |input_value|
        return false unless valid_float_param?(input_value) 
      end
    elsif options[:cherrypick][:action] == "micro_litre"
      [options[:micro_litre_volume_required]].each do |input_value|
        return false unless valid_float_param?(input_value)  
      end
    else
      return false
    end
    
    true
  end

  def valid_float_param?(input_value)  
    return false  if input_value.blank? || input_value.to_f <= 0.0
    true
  end 
end
