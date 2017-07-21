# We'll try and do this through the API with the live version

namespace :generic_lims do
  task update_request_types: :environment do
    IlluminaC::Requests.update_request_types
  end
end
