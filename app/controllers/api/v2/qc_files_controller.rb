# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for QcFile
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class QcFilesController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
    end

    class QcFileProcessor < JSONAPI::Processor
      before_create_resource :prepare_temporary_file

      private

      def prepare_temporary_file
        filename, contents = required_attributes
        tempfile = create_temporary_file(filename, contents)

        context.merge!(filename:, tempfile:)
      end

      # Validate that attributes contains both the filename and the contents of the QcFile.
      def required_attributes
        attributes = params[:data][:attributes]

        filename = attributes[:filename]
        raise JSONAPI::Exceptions::ParameterMissing, 'filename' if filename.nil?

        contents = attributes[:contents]
        raise JSONAPI::Exceptions::ParameterMissing, 'contents' if contents.nil?

        [filename, contents]
      end

      # Create a temporary file with the contents.
      def create_temporary_file(filename, contents)
        # The filename for a Tempfile is passed as an array with the basename and extension.
        # e.g. [ 'file', '.csv' ]
        filename_components = [File.basename(filename, '.*'), File.extname(filename)]
        Tempfile.open(filename_components) do |file|
          file.write(contents)
          return file
        end
      end
    end
  end
end
