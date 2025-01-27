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
      # Validate that attributes contains both the filename and the contents of the QcFile.
      def validate_required_attributes(attributes)
        errors = []

        filename = attributes[:filename]
        errors += JSONAPI::Exceptions::ParameterMissing.new('filename').errors if filename.nil?

        contents = attributes[:contents]
        errors += JSONAPI::Exceptions::ParameterMissing.new('contents').errors if contents.nil?

        [filename, contents, errors]
      end

      # Create a temporary file with the contents.
      def create_tempfile(filename, contents)
        # The filename for a Tempfile is passed as an array with the basename and extension.
        # e.g. [ 'file', '.csv' ]
        filename_components = [File.basename(filename, '.*'), File.extname(filename)]
        Tempfile.open(filename_components) do |file|
          file.write(contents)
          return file
        end
      end

      # Override the default behaviour for a JSONAPI::Processor when creating a new resource.
      # We need to parse the filename and contents attributes so that we can generate a temporary file for the new
      # QcFile model object. Replacing the fields with these values after the new QcFile was created does not generate
      # the file correctly in the database. The CarrierWave library needs these values sooner.
      def create_resource
        data = params[:data]
        attributes = data[:attributes]
        filename, contents, errors = validate_required_attributes(attributes)

        return JSONAPI::ErrorsOperationResult.new(JSONAPI::BAD_REQUEST, errors) unless errors.empty?

        tempfile = create_tempfile(filename, contents)
        resource = QcFileResource.create_with_tempfile(context, tempfile, filename)
        result = resource.replace_fields(data)

        JSONAPI::ResourceOperationResult.new((result == :completed ? :created : :accepted), resource)
      end
    end
  end
end
