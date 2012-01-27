# This migration should
class RequestQuota < ActiveRecord::Base ; end

class RemoveBadRecordsInRequestQuotas < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.trascaction do
      bad_request_quotas = RequestQuota.find_by_sql(<<END_OF_SQL
select request_quotas.*, requests.id as missing_id
from request_quotas
left outer join requests
on request_quotas.request_id=requests.id
having missing_id is null;
END_OF_SQL
      )

      bad_request_quotas.each(&:destroy)
    end

  end

  def self.down
    # There is no way to undo this!
    say "There is no way to undo this data migration"
  end
end
