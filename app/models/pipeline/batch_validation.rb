# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

module Pipeline::BatchValidation
  def validation_of_batch(batch)
    # Using throw and catch enables us to skip over the request validation without actually
    # having to know whether it was needed or not.
    catch(:no_requests_in_batch) do
      validation_of_requests(batch.requests) do |message|
        batch.errors.add(:requests, message)
      end
    end
  end

  def validation_of_requests(requests)
    throw :no_requests_in_batch if requests.blank?
    yield('too many requests specified') if not max_size.nil? and requests.size > max_size
    yield('has incorrect type') unless (requests.map(&:request_type_id) - request_types_including_controls.map(&:id)).empty?
  end
  private :validation_of_requests

  # Overridden by pipeline implementations to ensure that the batch is valid for completion.  By
  # default this does nothing.
  def validation_of_batch_for_completion(batch)
  end
end
