# frozen_string_literal: true

class SprintController < ApplicationController
  def show
    print "****** show ******"
  end

  def action
    print "****** action ******"
    Sprint.print_request
  end
end
