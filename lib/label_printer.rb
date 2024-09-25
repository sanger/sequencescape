# frozen_string_literal: true
require_relative 'label_printer/label/multiple_labels'
require_relative 'label_printer/label/base_plate'
require_relative 'label_printer/label/base_tube'

Dir["#{File.dirname(__FILE__)}/label_printer/**/*.rb"].each { |file| require file }

module LabelPrinter
end
