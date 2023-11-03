# frozen_string_literal: true
require_relative 'label_printer/label'
require_relative 'label_printer/label/base_plate'
require_relative 'label_printer/label/base_tube'

Dir["#{File.dirname(__FILE__)}/**/*.rb"].each { |file| require file }

module LabelPrinter
end
