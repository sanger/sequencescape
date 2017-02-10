# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

# require './app/api/core/service'
module Api
  class EndpointHandler < ::Core::Service
    class << self
      def registered_mimetypes
        @registered_mimetypes || []
      end

      # We can't use the built in provides, as the accepted mimetimes are fixed when the route is set up.
      def file_requested(bool)
        condition do
          request.acceptable_media_types.prioritize(registered_mimetypes).present? == bool
        end
      end

      def file_attatched(bool)
        condition do
          registered_mimetypes.include?(request.content_type) == bool
        end
      end

      def file_addition(action, http_method)
        send(http_method, %r{^/([\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12})(?:/([^/]+(?:/[^/]+)*))?$}, file_attatched: true) do
          raise Core::Service::ContentFiltering::InvalidRequestedContentTypeOnFile if request.acceptable_media_types.prioritize(registered_mimetypes).present?
          report('file') do
            filename = /filename="([^"]*)"/.match(request.env['HTTP_CONTENT_DISPOSITION']).try(:[], 1) || 'unnamed_file'
            begin

              file = Tempfile.new(filename)
              file.binmode
              file.unlink
              file.write(request.body.read)
              # Be kind...
              file.rewind
              request.body.rewind
              uuid_in_url, parts = params[:captures][0], params[:captures][1].try(:split, '/') || []
              uuid = Uuid.find_by(external_id: uuid_in_url) or raise ActiveRecord::RecordNotFound, 'UUID does not exist'
              handle_request(:instance, request, action, parts) do |request|
                request.io     = lookup_for_class(uuid.resource.class) { |e| raise e }
                request.target = request.io.eager_loading_for(uuid.resource.class).include_uuid.find(uuid.resource_id)
                request.file = file
                request.filename = filename
              end
            ensure
              file.close!
            end
          end
        end
      end

      def file_model_addition(action, http_method)
        send(http_method, %r{^/([^\d/][^/]+(?:/[^/]+){0,2})$}, file_attatched: true) do
          raise Core::Service::ContentFiltering::InvalidRequestedContentType if request.acceptable_media_types.prioritize(registered_mimetypes).present?
          report('model') do
            filename = /filename="([^"]*)"/.match(request.env['HTTP_CONTENT_DISPOSITION']).try(:[], 1) || 'unnamed_file'
            begin
              file = Tempfile.new(filename)
              file.write(request.body.read)
              # Be kind...
              file.rewind
              request.body.rewind
              determine_model_from_parts(*params[:captures].join.split('/')) do |model, parts|
                handle_request(:model, request, action, parts) do |request|
                  request.io     = lookup_for_class(model) { |_| nil }
                  request.target = model
                  request.file = file
                  request.filename = filename
                end
              end
            ensure
              file.close!
            end
          end
        end
      end

      def file_model_action(_action, http_method)
        send(http_method, %r{^/([^\d/][^/]+(?:/[^/]+){0,2})$}, file_requested: true) do
          report('model') do
            raise Core::Service::ContentFiltering::InvalidRequestedContentType
          end
        end
      end

      def file_action(action, http_method)
        send(http_method, %r{^/([\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12})(?:/([^/]+(?:/[^/]+)*))?$}, file_requested: true) do
          report('file') do
            uuid_in_url, parts = params[:captures][0], params[:captures][1].try(:split, '/') || []
            uuid = Uuid.find_by(external_id: uuid_in_url) or raise ActiveRecord::RecordNotFound, 'UUID does not exist'

            file_through = return_file(request, action, parts) do |request|
              request.io     = lookup_for_class(uuid.resource.class) { |e| raise e }
              request.target = request.io.eager_loading_for(uuid.resource.class).include_uuid.find(uuid.resource_id)
            end
            uuid.resource.__send__(file_through) { |file| send_file file.path, filename: file.filename }
          end
        end
      end

      def instance_action(action, http_method)
        send(http_method, %r{^/([\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12})(?:/([^/]+(?:/[^/]+)*))?$}, file_attatched: false, file_requested: false) do
          report('instance') do
            uuid_in_url, parts = params[:captures][0], params[:captures][1].try(:split, '/') || []
            uuid = Uuid.find_by(external_id: uuid_in_url) or raise ActiveRecord::RecordNotFound, 'UUID does not exist'
            handle_request(:instance, request, action, parts) do |request|
              request.io     = lookup_for_class(uuid.resource.class) { |e| raise e }
              request.target = request.io.eager_loading_for(uuid.resource.class).include_uuid.find(uuid.resource_id)
            end
          end
        end
      end

      def model_action(action, http_method)
        send(http_method, %r{^/([^\d/][^/]+(?:/[^/]+){0,2})$}, file_attatched: false, file_requested: false) do
          report('model') do
            determine_model_from_parts(*params[:captures].join.split('/')) do |model, parts|
              handle_request(:model, request, action, parts) do |request|
                request.io     = lookup_for_class(model) { |_| nil }
                request.target = model
              end
            end
          end
        end
      end

      def register_mimetype(mimetype)
        @registered_mimetypes ||= []
        @registered_mimetypes.push(mimetype).uniq!
      end
    end

    def registered_mimetypes
      self.class.registered_mimetypes
    end

    def lookup_for_class(model)
      ::Core::Io::Registry.instance.lookup_for_class(model)
    rescue ::Core::Registry::UnregisteredError => exception
      yield(exception)
    end
    private :lookup_for_class

    # Report the performance and status of any request
    def report(handler)
      start = Time.now
      Rails.logger.info("API[start]: #{handler}: #{request.fullpath}")
      yield
    ensure
      Rails.logger.info("API[handled]: #{handler}: #{request.fullpath} in #{Time.now - start}s")
    end
    private :report

    # Not ideal but at least this allows us to pick up the appropriate model from the URL.
    def determine_model_from_parts(*parts)
      (1..parts.length).to_a.reverse.each do |n|
        model_name, remainder = parts.slice(0, n), parts.slice(n, parts.length)
        model_constant = model_name.join('/').classify
        begin
          constant = model_constant.constantize
        rescue NameError
          # Using const_defined? disrupts rails eager loading 'magic'
          constant = nil
        end
        next unless constant
        return yield(constant, remainder)
      end
      raise StandardError, "Cannot route #{parts.join('/').inspect}"
    end
    private :determine_model_from_parts

    def handle_request(handler, http_request, action, parts)
      endpoint_lookup, io_lookup =
        case handler
        when :instance then [:endpoint_for_object, :lookup_for_object]
        when :model    then [:endpoint_for_class,  :lookup_for_class]
        else raise StandardError, "Unexpected handler #{handler.inspect}"
        end

      request =
        ::Core::Service::Request.new(requested_url = http_request.fullpath) do |request|
          request.service = self
          request.path    = parts
          request.json    = @json
          yield(request)
        end

      endpoint = send(endpoint_lookup, request.target)
      Rails.logger.info("API[endpoint]: #{handler}: #{requested_url} handled by #{endpoint.inspect}")
      body(request.send(handler, action, endpoint))
    end

    def return_file(http_request, action, parts)
      request =
        ::Core::Service::Request.new(requested_url = http_request.fullpath) do |request|
          request.service = self
          request.path    = parts
          request.json    = @json
          yield(request)
        end

      endpoint = endpoint_for_object(request.target)
      file_through = request.instance(action, endpoint).handled_by.file_through(request_accepted)
      raise Core::Service::ContentFiltering::InvalidRequestedContentType if file_through.nil?
      Rails.logger.info("API[endpoint]: File: #{requested_url} handled by #{endpoint.inspect}")
      file_through
    end

    ACTIONS_TO_HTTP_VERBS = {
      create: :post,
      read: :get,
      update: :put,
      delete: :delete
    }

    ACTIONS_TO_HTTP_VERBS.each do |action, verb|
      instance_action(action, verb)
      model_action(action, verb)
      file_action(action, verb)
      file_model_action(action, verb)
    end

    {
      create_from_file: :post,
      update_from_file: :put
    }.each do |action, verb|
      file_addition(action, verb)
      file_model_addition(action, verb)
    end
  end
end
