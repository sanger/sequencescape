
class AddFlexibleCherrypickPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      pl = FlexibleCherrypickPipeline.create!(
        name: 'Flexible Cherrypick',
        automated: false,
        active: true,
        location: Location.find_by(name: 'Sample logistics freezer'),
        group_by_parent: true,
        asset_type: nil,
        paginate: 0,
        summary: true,
        externally_managed: false,
        group_name: 'Sample Logistics',
        min_size: 1,
        control_request_type_id: 0
      ) do |pl|
        pl.workflow = LabInterface::Workflow.new(name: 'Flexible Cherrypick', pipeline: pl)
        pl.request_types << RequestType.find_by(key: 'flexible_cherrypick')
      end
      MultiplexedCherrypickingTask.create!(workflow: pl.workflow, name: 'Set Plate Layout', lab_activity: true)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      FlexibleCherrypickPipeline.find_by(name: 'Flexible Cherrypick').workflow.destroy
      FlexibleCherrypickPipeline.find_by(name: 'Flexible Cherrypick').destroy
    end
  end
end
