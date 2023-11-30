# frozen_string_literal: true

# Will construct a SpikedBuffer tube (contains PhiX control sample)
class UatActions::GenerateSpikedBufferTube < UatActions
  self.title = 'Generate spiked buffer tube'

  # The description displays on the list of UAT actions to provide additional information
  self.description = 'Generates one or more spiked buffer tubes, with a parent stock tube.'
  self.category = :auxiliary_data

  # Form fields
  form_field :tube_count,
             :number_field,
             label: 'Number of tubes',
             help: 'The number of spiked buffer tubes that should be generated',
             options: {
               minimum: 1
             }

  #
  # Returns a default copy of the UatAction which will be used to fill in the form
  #
  # @return [UatActions::GenerateSpikedBufferTube] A default object for rendering a form
  def self.default
    new(tube_count: 1)
  end

  #
  # [perform description]
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    # Called by the controller once the form is filled in. Add your actual actions here.
    # All the form fields are accessible as simple attributes.
    # Return true if everything works
    timestamp = Time.now.to_i

    parent_stocks = create_phix_stocks(timestamp)
    return false unless parent_stocks

    spiked_buffers = create_spiked_buffers(timestamp, parent_stocks)
    return false unless spiked_buffers

    spiked_buffers.each_with_index { |tube, index| report["tube_#{index}"] = tube.human_barcode }
    true
  end

  def create_phix_stocks(timestamp)
    phi_x_stock_params = {
      name: "uat-phix-stock-#{timestamp}",
      tags: 'Dual',
      concentration: 10,
      number: 1,
      study_id: PhiX.default_study_option&.id
    }
    parent_stock = PhiX::Stock.new(phi_x_stock_params)
    return nil unless parent_stock.save

    parent_stock.created_stocks
  end

  def create_spiked_buffers(timestamp, parent_stocks)
    phi_x_spiked_buffers_params = {
      name: "uat-phix-spikedbuffer-#{timestamp}",
      parent_barcode: parent_stocks.first.human_barcode,
      concentration: 10,
      number: tube_count,
      volume: 10
    }
    spiked_buffer = PhiX::SpikedBuffer.new(phi_x_spiked_buffers_params)
    return nil unless spiked_buffer.save

    spiked_buffer.created_spiked_buffers
  end
end
