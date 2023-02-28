# frozen_string_literal: true

BioscanBuilderJob =
  Struct.new(:barcode) do
    def perform
      puts "DEBUG: Bioscan Job with barcode = #{barcode}"
    end
  end
