# frozen_string_literal: true

# Controller to test SPrint
class SprintController < ApplicationController
  # rubocop:disable Rails/Output
  def show
    print '****** show ******'
  end

  def action
    print '****** action ******'
    Sprint.print_request
  end
  # rubocop:enable Rails/Output
end
