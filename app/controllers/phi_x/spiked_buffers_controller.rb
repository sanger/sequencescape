# frozen_string_literal: true

# Takes form input from {PhiXesController#show} and generates a {SpikedBuffer} using
# the factory {PhiX::SpikedBuffer}
class PhiX::SpikedBuffersController < ApplicationController
  def create
    @spiked_buffer = PhiX::SpikedBuffer.new(phi_x_spiked_buffers_params)
    if @spiked_buffer.save
      @spiked_buffers = @spiked_buffer.created_spiked_buffers
      render :show
    else
      render :new
    end
  end

  private

  def phi_x_spiked_buffers_params
    params.require(:phi_x_spiked_buffer).permit(:name, :parent_barcode, :concentration, :buffer, :number, :volume)
  end
end
