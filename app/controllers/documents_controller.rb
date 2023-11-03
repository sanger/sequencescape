# frozen_string_literal: true
class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    send_data @document.current_data, filename: @document.filename, type: @document.content_type, disposition: 'inline'
  end
end
