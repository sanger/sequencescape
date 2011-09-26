class RequestHasManyQuotas < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :request_quotas do |t|
        t.integer :request_id
        t.integer :quota_id
      end
      add_index :request_quotas, [:quota_id, :request_id]

      add_column :quotas, :preordered_count, :integer, :default => 0

      request_type_ids = RequestType.all.map { |rt| rt.id }
      # Create missing quota on every project
      Project.find_in_batches(:include => :quotas) do |projects|
        projects.each do |project|
          #create missing quota
          (request_type_ids-project.quotas.map(&:request_type_id)).each do |rt_id|
            project.quotas.create!(:limit => 0, :request_type_id => rt_id)
          end
        end
      end

      # backfill request_quota
      request_type_ids.each do |rt_id|
        ActiveRecord::Base.connection.execute <<-EOS
      INSERT INTO request_quotas (request_id, quota_id)
      SELECT r.id , q.id
      FROM requests r, quotas q
      WHERE r.project_id =  q.project_id
      AND q.request_type_id = #{rt_id}
      AND (#{
        %w[passed pending blocked started].map{ |s| "r.state = '#{s}'" }.join(" OR ")
      })
      EOS
      end
    end
    #remove project_id
    rename_column :requests, :project_id, :initial_project_id
  end

  def self.down
    remove_column :quotas, :preordered_count, :integer
    rename_column :requests, :initial_project_id, :project_id
    drop_table :request_quotas
  end
end
