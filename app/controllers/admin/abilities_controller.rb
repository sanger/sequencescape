# frozen_string_literal: true

require './lib/ability_analysis'

# Simple controller to summarise the allocated abilities
class Admin::AbilitiesController < ApplicationController
  authorize_resource

  def index
    ability_analysis = AbilityAnalysis.new
    @roles = ability_analysis.all_roles
    @permissions = ability_analysis.permission_matrix
  end
end
