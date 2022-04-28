# frozen_string_literal: true
class Endpoints::OrderTemplates < Core::Endpoint::Base # rubocop:todo Style/Documentation
  model {}

  instance do
    nested('orders') do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction do
          attributes = ::Io::Order.map_parameters_to_attributes(request.json)
          attributes[:user] = request.user if request.user.present?
          request.target.create_order!(attributes)
        end
      end
    end
  end
end

# Ensure that this template is used for the SubmissionTemplate model whilst it exists.  Without this we
# would need to implement another endpoint and the end users would be confused.
Endpoints::SubmissionTemplates = Endpoints::OrderTemplates
