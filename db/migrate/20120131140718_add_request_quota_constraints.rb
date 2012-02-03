class RequestQuota < ActiveRecord::Base ; end

class AddRequestQuotaConstraints < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      say 'Applying null constraints to the request_quotas table...'

      connection.execute('alter table request_quotas modify column request_id int(11) not null;')

      connection.execute('alter table request_quotas modify column quota_id int(11) not null;')

      say 'Applying foreign key constraints to the request_quotas table...'
      connection.execute('alter table request_quotas add constraint foreign key fk_request_quotas_to_quotas (quota_id) references quotas (id);')

      connection.execute('alter table request_quotas add constraint foreign key fk_request_quotas_to_requests (request_id) references requests(id);')
    end
  end

  def self.down
  end
end
