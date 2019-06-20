# frozen_string_literal: true

# Display of {SequenomQcPlate sequenom plate}. These plates are no longer actively generated
class SequenomQcPlatesController < ApplicationController
  def index
    @sequenom_qc_plates = SequenomQcPlate.page(params[:page]).order(created_at: :desc)
  end
end
