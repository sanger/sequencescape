# frozen_string_literal: true
module Pipeline::BatchValidation
  def validation_of_batch(batch)
    # Using throw and catch enables us to skip over the request validation without actually
    # having to know whether it was needed or not.
    catch(:no_requests_in_batch) do
      validation_of_requests(batch.requests) { |message| batch.errors.add(:requests, message) }
    end
  end

  def validation_of_requests(requests)
    throw :no_requests_in_batch if requests.blank?
    yield('too many requests specified') if (not max_size.nil?) && (requests.size > max_size)
    approved_request_types = request_types_including_controls.map(&:id)
    yield('has incorrect type') unless requests.all? { |r| approved_request_types.include?(r.request_type_id) }
  end
  private :validation_of_requests
end
