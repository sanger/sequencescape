module SampleManifestExcel
  require_relative 'upload/row'

  class Upload
    include ActiveModel::Validations

    attr_reader :columns, :sanger_sample_id_column

    validates_presence_of :sanger_sample_id_column
    validate :check_columns

    def initialize(headings, column_list)
      @columns = column_list.extract(headings)
      @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
    end

  private

    def check_columns
      unless columns.valid?
        columns.errors.each do |key, value|
          errors.add key, value
        end
      end
    end
  end
end
