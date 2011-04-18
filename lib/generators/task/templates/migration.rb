class Add<%= singular_name.camelize %>Task < ActiveRecord::Migration
  def self.up
    # Fill in the workflow and the ordering of the task (sorted)
    workflow = LabInterface::Workflow.find_by_name('Fill in the workflow')
    <%= singular_name.camelize %>Task.create!( :name => '<%= singular_name.gsub(/_/,' ') %>', :sorted => 1, :batched => true, :workflow => workflow )
  end

  def self.down
  end
end