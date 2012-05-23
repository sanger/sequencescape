require 'control_request_type_creation'
Pipeline.send(:include, ControlRequestTypeCreation)

# class Pipeline < ActiveRecord::Base
#   has_and_belongs_to_many :request_types
#   belongs_to :control_request_type, :class_name => 'RequestType'
# end

class MapPipelinesToControlRequestTypes < ActiveRecord::Migration

  class << self
    def up
      ActiveRecord::Base.transaction do
        add_column(:pipelines, :control_request_type_id, :integer, :null => false)

        Pipeline.all.each do |pipeline|
          say "Adding Control RequestType to pipeline: #{pipeline.name}"
          pipeline.add_control_request_type.save!
        end
      end
    end

    def down
      remove_column(:pipelines, :control_request_type_id)
      say "Removing Control RequestTypes"
      RequestType.find_all_by_request_class_name(ControlRequest.to_s).each(&:destroy)
    end
  end
end
