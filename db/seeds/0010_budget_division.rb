# frozen_string_literal: true

budget_divisions = ['Unallocated', 'Pathogen (including malaria)', 'Human variation']

budget_divisions.each do |name|
  BudgetDivision.create!(name: name)
end
