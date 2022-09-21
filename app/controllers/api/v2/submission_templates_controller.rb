# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for submission template
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class SubmissionTemplatesController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.

      # def update

      #   #   orders.map(&:permit!)
      #   #   orders.each do |order|
      #   #     order['user'] = User.with_uuid(order['user']).first
      #   #     order['assets'] = Receptacle.with_uuid(order['assets'])
      #   #     _model.create_order!(order)
      #   #   end
      #   # end
  
      #   render json:
      #             JSONAPI::ResourceSerializer
      #               .new(SubmissionTemplateResource)
      #               .serialize_to_hash(SubmissionTemplateResource.new(params, nil)),
      #           status: :created
      # end
    end
  end
end
