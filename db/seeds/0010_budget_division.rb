# frozen_string_literal: true

budget_divisions = ['Unallocated', 'Pathogen (including malaria)', 'Human variation']

budget_divisions.each { |name| BudgetDivision.create!(name:) }
