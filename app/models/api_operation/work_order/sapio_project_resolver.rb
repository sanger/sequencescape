# frozen_string_literal: true

# Finds the project for a Sapio work order's cost code, creating it when none exists.
# Projects are matched with their name; projects are named "SAPIO-<cost_code>".
class ApiOperation::WorkOrder::SapioProjectResolver
  NAME_PREFIX = 'SAPIO'

  def initialize(cost_code)
    @cost_code = cost_code.to_s.strip
    @name = "#{NAME_PREFIX}-#{@cost_code}"
  end

  # @return [Project]
  # @raise [ActiveRecord::RecordInvalid] if the project cannot be created
  def find_or_create
    find || create
  end

  private

  def find
    Project.find_by(name: @name)
  end

  def create
    Project.create!(
      name: @name,
      project_metadata_attributes: { project_cost_code: @cost_code }
    )
  end
end
