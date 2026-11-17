# frozen_string_literal: true

# Finds the project for a Sapio work order's cost code, creating it when none exists.
# Projects are matched with their name; projects are named "SAPIO-<cost_code>".
# A created project is approved, active, externally funded and in the Sapio budget division,
# so that submissions can be made for it.
class ApiOperation::WorkOrder::SapioProjectResolver
  NAME_PREFIX = 'SAPIO'
  BUDGET_DIVISION = 'Sapio'
  FUNDING_MODEL = 'External'

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
      state: Project::ACTIVE_STATE,
      approved: true,
      project_metadata_attributes: {
        project_cost_code: @cost_code,
        project_funding_model: FUNDING_MODEL,
        budget_division: BudgetDivision.find_or_create_by!(name: BUDGET_DIVISION)
      }
    )
  end
end
