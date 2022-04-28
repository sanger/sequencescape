# frozen_string_literal: true
xml.instruct!
xml.requests(api_data) do
  if @requests.empty?
    xml.comment!('There were no results returned. You might want to check your parameters if you expected any results.')
  else
    @requests.each do |r|
      xml.request do
        xml.id r.id
        unless r.request_type.nil?
          xml.comment! r.request_type.name
          xml.type r.request_type.key
        end
        xml.attempt r.attempts.size
        xml.created_at r.created_at
        xml.comment! 'Below is a list of the key/value pairs that are related to this request'
        xml.properties do
          # Nothing here, was item.properties but that was always empty!
        end
      end
    end
  end
end
