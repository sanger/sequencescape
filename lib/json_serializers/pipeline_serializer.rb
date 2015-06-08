module JsonSerializers
  module PipelineSerializer
    def self.to_json(pipeline)
      hash = pipeline.attributes.dup
      hash[:control_request_type_key] = pipeline.control_request_type.key unless pipeline.control_request_type.nil?
      hash[:location_name] = pipeline.location.name
      hash[:request_types_keys] = pipeline.request_types.map(&:key)
      workflow_obj = pipeline.workflow.attributes.dup.tap do |w|
        w.delete("id")
        w.delete("pipeline_id")
        w[:tasks] = pipeline.workflow.tasks.map do |task|
          task.attributes.dup.merge({
            :class => task.sti_type
            })
        end
      end
      hash[:workflow] = workflow_obj
      hash[:request_information_type_labels] = pipeline.request_information_types.map(&:label)
      hash[:sti_type] = pipeline.class.to_s
      hash.to_json
    end

    def self.build(json)
      ActiveRecord::Base.transaction do |t|
        params = ActiveSupport::JSON.decode(json).symbolize_keys

        control_request_type_key = params.delete(:control_request_type_key)
        params[:control_request_type_id] = control_request_type_key.nil? ? 0 : RequestType.find_by_key(control_request_type_key).id

        params[:location] = Location.first(:conditions => { :name => params.delete(:location_name) }) or raise StandardError, "Cannot find 'Library creation freezer' location"
        params[:request_types] = params.delete(:request_types_keys).map{|key| RequestType.find_by_key(key)}

        workflow_info = params.delete(:workflow).symbolize_keys
        tasks_info = workflow_info.delete(:tasks).map(&:symbolize_keys)

        workflow_info[:name] = params[:name] if workflow_info[:name].nil?
        params[:workflow] = LabInterface::Workflow.create!(workflow_info)

        tasks_info.each do |details|
          details.delete(:class).constantize.create!(details.merge(:workflow => params[:workflow]))
        end

        request_information_type_labels = params.delete(:request_information_type_labels)

        params.delete(:sti_type).constantize.new(params).tap do |pipeline|
          request_information_type_labels.each do |label|
            PipelineRequestInformationType.create!(:pipeline => pipeline,
              :request_information_type => RequestInformationType.find(:first, :conditions => { :label => label}))
          end
        end
      end
    end
  end
end
