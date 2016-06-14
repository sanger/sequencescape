module SampleManifestExcel

  class Validation

    include HashAttributes

    set_attributes :options, :range_name

    def initialize(attributes = {})
      create_attributes(attributes)
    end

    def update(attributes = {})
      if range_required?
        options[:formula1] = attributes[:range].absolute_reference
      end

      if attributes[:worksheet].present?
        @worksheet_validation = attributes[:worksheet].add_data_validation(attributes[:reference], options)
      end
    end

    def range_required?
      range_name.present?
    end

    def formula1
      options[:formula1]
    end

    def valid?
      options.present?
    end

    def empty?
      false
    end

    def saved?
      @worksheet_validation.present?
    end

  end

end