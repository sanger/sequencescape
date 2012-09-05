require 'db_charmer'

LOADING_SUFFIX="_loading"
LAST_VERSION_SUFFIX="_last_snapshot"
WAREHOUSE_DB_CONF = :"#{Rails.env}_warehouse"
TABLE_TYPE = "MyISAM" # InnoDB, MyISAM, ARCHIVE

require "#{File.expand_path(File.dirname(__FILE__))}/cron_tools"
DbCharmer.connections_should_exist = TRUE
    # check db-charmer for more info
    # http://github.com/kovyrin/db-charmer


MODEL_TABLES = { # class_name => base table_name
  "NewBilling" => "new_billing",
  "ProjectInformation" => "project_information",
  "StudyInformation" => "study_information",
  "ItemInformation" => "item_information",
  "AssetInformation" => "asset_information",
  "MbQuota" => "quotas",
  "MbSample" => "samples",
  "MbRequest" => "requests",
  "MbRequestNew" => "requests_new",
  "StudySampleReport" => "study_sample_reports",
  # "SequencingSummary" => "sequencing_summary",
  "PropertyInformation" => "property_information",
  "ApiVersion" => "api_version",
  "Library" => "library",
  "MbAsset" => "assets",
  "LibraryInformation" => "library_information",
  "MultiplexInformation" => "multiplex_information",
  "ItemIdMapping" => "item_id_mapping",
  "SampleIdMapping" => "sample_id_mapping",
  "MbAssetLinks" => "asset_links",
}

TABLE_NAMES = MODEL_TABLES.values
MODELS = MODEL_TABLES.map do |class_name, table_name|
  model = eval <<-CODE
    class #{class_name} < ActiveRecord::Base
      db_magic :connection => WAREHOUSE_DB_CONF
      set_table_name :"#{table_name}#{LOADING_SUFFIX}"
    end
    #{class_name}
  CODE
  # maps to: Array of resulting Classes
end

# allows us to use the :type column; we don't need the STI feature
MbRequest.inheritance_column = "junk"
MbRequestNew.inheritance_column = "junk"

$child_pids = []
def wait_for_child(pid=nil)
  begin
    pid, child_result = (pid.nil? ? Process.wait2 : Process.waitpid2(pid))
    unless child_result.exitstatus.zero?
      $child_pids.each {|child_pid| Process.kill('TERM', child_pid) rescue true}
      raise "Child PID:#{pid} exited with status #{child_result.exitstatus} - aborting"
    end
  rescue Errno::ECHILD
    true
  end
end

def fork_and_reconnect_db(msg)
  on_all_db_connections(:disconnect!)
  child_pid = fork do
    begin
      Script.say_with_time(msg) do
        on_all_db_connections(:reconnect!)
        yield
        sleep 10
        Script.say(msg + " finished")
      end
    end
  end
  on_all_db_connections(:reconnect!)
  return child_pid
end

def on_all_db_connections(action)
  ObjectSpace.each_object(ActiveRecord::ConnectionAdapters::AbstractAdapter).each {|a| a.send(action)}
end

def run_in_parallel(msg="fork")
  $child_pids << fork_and_reconnect_db(msg) do
    yield
  end
  wait_for_child if $child_pids.length >= 3 # Decides level of parallelism
end

def final_wait
  i = 0
  $child_pids.each do |pid|
    wait_for_child(pid)
    puts "PID #{pid} collected (#{i += 1} of #{$child_pids.length})" if ENV['TEST_RUN']
  end
  on_all_db_connections(:reconnect!)
end

class Script < ActiveRecord::Migration
  def self.put_project_billing(division, project)
    stuffing = []
    cc = project.project_metadata.project_cost_code
    cost_code = cc if cc
    project.billing_events.each do |billing_event|
      date = billing_event.entry_date.strftime("%Y-%m-%d")
      billing_event.reference =~ /R(\d+)/
      request = Request.find_by_id($1, :include => [ :request_type, :request_metadata ])
      price = 1
      library_type = ''

      if !request.nil? && [2,3].include?(request.request_type_id) && !request.request_metadata.read_length.nil?
        price = request.request_metadata.read_length
      end
      library_type = request.request_metadata.library_type if !request.nil?

      stuffing << {
        :price => price,
        :library_type => library_type,
        :reference => billing_event.reference,
        :division => division,
        :project_id => project.id,
        :project_name => project.name,
        :cost_code => cost_code,
        :created_by => billing_event.created_by,
        :billing_event_id => billing_event.id,
        :entry_date => date,
        :kind => billing_event.kind,
        :description => billing_event.description,
        :quantity => billing_event.quantity,
        :request_id => request.nil? ? nil: request.id
      }

      #@log.debug "<New Billing Event> :id=> '#{billing_event.id}', :project=> '#{project.id}', :desc=> '#{billing_event.description}'"
    end
    batch_load(NewBilling, stuffing)
  end

  def self.put_asset
    Asset.find_in_batches do |group|
      stuffing = []
      preloaded_events = []
      # HEY, this is cheating! Shamelessly peeking into a model like this...
      Event.find_all_by_eventful_id_and_eventful_type_and_family(group.map {|a| a.id}, "Asset", "scanned_into_lab").each do |event|
        preloaded_events[event.eventful_id] = event.content
      end
      group.each do |asset|
        stuffing << {
          :asset_id => asset.id,
          :name => asset.name,
          :external_release => asset.external_release,
          :public_name => asset.public_name,
          :asset_type => asset.sti_type,
          :qc_state => asset.qc_state,
          :volume => asset.volume,
          :concentration => asset.concentration,
          :location => (asset.is_a?(Well) ? 'Asset' : 'Location'),
          :scanned_date => preloaded_events[asset.id] #asset.scanned_in_date
        }
      end
      batch_load(MbAsset, stuffing)
      break if ENV['TEST_RUN']
    end
  end

  def self.put_batch(batch)
    stuffing = {:lib => [], :libinf => []}
    batch.requests.each do |request|
      if request.try(:asset)
        batch.user_id.nil? ? username = "" : username = batch.user.login
        stuffing[:lib] << {
          :item_id => request.item_id,
          :asset_id => request.asset.id,
          :asset_type => request.asset.sti_type,
          :request_id => request.id,
          :name => request.asset.name,
          :batch_id => batch.id,
          :pipeline_id => batch.pipeline_id,
          :position => request.position(batch),
          :batch_state => batch.state,
          :state_date => batch.updated_at,
          :qc_state => batch.qc_state,
          :sample_id => request.sample_id,
          :created_at => request.asset.created_at,
          :batch_created_at=>batch.created_at,
          :user_login => username
        }

        #@log.debug "<Library> :request => '#{request.id}', :asset => '#{request.asset.id}', :batch => '#{batch.id}'"

        request.lab_events.each do |event|
          if event.descriptor_fields
            event.descriptor_fields.each do |field|
              stuffing[:libinf] << {
                :item_id => request.item_id,
                :asset_id => request.asset_id,
                :target_asset_id => request.target_asset_id,
                :batch_id => event.batch_id,
                :description => event.description,
                :param => field,
                :value => event.descriptor_value(field)
              }
            end
          end

          #@log.debug "<LibraryInformation> :event => '#{event.id}', :request => '#{request.id}'"

        end
      end
    end
    batch_load(Library, stuffing[:lib])
    batch_load(LibraryInformation, stuffing[:libinf])
  end

  # Find Requests putting MultiplexedLibraryTubes into Lanes
  def self.put_multiplexing()
    Tag.cache do
      Request.find_in_batches(:batch_size=>200,:include => [:asset],
      :conditions => { "assets.sti_type" => "MultiplexedLibraryTube"}) do |group|
        stuffing = []
        group.each do |mlreq|
          numrows = 0
          mlreq.tags.each do |idxlib|
            # Ununsed guard that fails with current data.
#            raise "Expected (indexed) library of a Sample, but got one with a tag on #{idxlib.inspect}" unless idxlib.sample_id.present?
            next unless idxlib.is_a?(LibraryTube)
            tag = idxlib.get_tag
            mlt = mlreq.asset
            mlreq.batch_requests.each do |batchreq| # mostly one Batch per Request, since Attempts have been disabled
              stuffing << {
                :batch_id => batchreq.batch_id,
                :position => batchreq.position,
                :asset_id => mlt.id,
                :pool_name => mlt.name,
                :sample_id => idxlib.sample_id,
                :library_asset_id => idxlib.id,
                :tag_id => tag && tag.map_id,
                :sequence => tag && tag.oligo,
                :tag_group_id => tag && tag.tag_group_id
              }
              numrows += 1
            end
          end
          #@log.debug "<MultiplexInformation> :request => '#{mlreq.id}' (#{numrows} rows)"
        end
        batch_load(MultiplexInformation, stuffing)
        break if ENV['TEST_RUN']
      end
    end
  end

  def self.put_property_and_requests
    Request.find_in_batches(:include => [:request_type, :request_metadata, :project, :study, :sample, :asset]) do |group|
      stuffing = {:pi => [], :mbr => [], :mbr_new => []}
      group.each do |request|
        request.request_metadata.class.attribute_details.each do |attribute|
          stuffing[:pi] << {
            :obj_id   => request.id,
            :obj_type => Request.to_s,
            :key      => attribute.name.to_s,
            :value    => request.request_metadata[attribute.name]
          }
          #@log.debug "<PropertyInformation> :property => '#{attribute.name}'"
        end

        if request.project
          project_id = request.project.id
          project_name = request.project.name
        else
          project_id = ""
          project_name = ""
        end

        if request.study
          study_id = request.study.id
          #          study_name = request.study.name
        else
          study_id = ""
          #          study_name = ""
        end

        if request.sample
          sample_id = request.sample.id
          sample_name = request.sample.name
        else
          sample_id = ""
          sample_name = ""
        end

        if request.asset
          asset_name = request.asset.name
          asset_closed = 1
        else
          asset_name = ""
          asset_closed = 0
        end

        request_type_name = request.request_type ? request.request_type.name : ""

        stuffing[:mbr] << {
          :request_id => request.id,
          :item_id => request.item_id,
          :study_id => study_id,
          :project_id => project_id,
          :project_name => project_name,
          :item_name => asset_name,
          :closed => asset_closed,
          :sample_id => sample_id,
          :sample_name => sample_name,
          :type => request_type_name,
          :state => request.state,
          :created_at => request.created_at.nil? ? nil : request.created_at.to_formatted_s(:db),
          :read_length => (request.request_metadata.read_length ? request.request_metadata.read_length : nil)
        }

        stuffing[:mbr_new] << {
          :request_id => request.id,
          :item_id => request.item_id,
          :asset_id => request.asset_id,
          :target_asset_id => request.target_asset_id,
          :study_id => study_id,
          :project_id => project_id,
          :project_name => project_name,
          :item_name => asset_name,
          :closed => asset_closed,
          :sample_id => sample_id,
          :sample_name => sample_name,
          :type => request_type_name,
          :state => request.state,
          :created_at => request.created_at.nil? ? nil : request.created_at.to_formatted_s(:db),
          :read_length => (request.request_metadata.read_length ? request.request_metadata.read_length : nil)
        }

        #@log.debug "<Request> :request => '#{request.id}'"
      end

      batch_load(PropertyInformation, stuffing[:pi])
      batch_load(MbRequest, stuffing[:mbr])
      batch_load(MbRequestNew, stuffing[:mbr_new])
      break if ENV['TEST_RUN']
    end
  end

  def self.run_all_steps
    run_in_parallel("put_property_and_requests") do
      put_property_and_requests()
    end
    run_in_parallel("property_information") do
      Sample.find_in_batches(:include => :sample_metadata) do |group|
        stuffing = {:mbs => [], :pi => []}
        group.each do |sample|
          stuffing[:mbs] << {
            :sample_id => sample.id,
            :name => sample.name
          }

          Sample::Metadata.attribute_details.each do |attribute|
            stuffing[:pi] << {
              :obj_id   => sample.id,
              :obj_type => sample.class.to_s,
              :key      => attribute.name.to_s,
              :value    => sample.sample_metadata[attribute.name]
            }
            #@log.debug "<PropertyInformation> :property => '#{attribute.name}', :sample => '#{sample.id}'"
          end
        end
        batch_load(MbSample, stuffing[:mbs])
        batch_load(PropertyInformation, stuffing[:pi])
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("put_asset") do
        put_asset()
    end
    run_in_parallel("put_batch") do
      Batch.find_each(:batch_size=>200, :include => [{:requests => :asset}]) do |batch|  #, :conditions => 'batches.id > 2050 AND batches.id < 2088'
        put_batch(batch)
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("put_multiplexing") do
      put_multiplexing()
    end
    run_in_parallel("put_project_billing") do
      ApiVersion.create({:version => RELEASE.api_version})
      Project.find(:all, :include => [:billing_events, :project_metadata]).group_by { |project| project.project_metadata.budget_division }.each do |division, projects|
        projects.each do |project|
          Script.put_project_billing(division, project)
        end
        break if ENV['TEST_RUN'] #puts "Completed batch of #{projects.size} projects for budget division #{division}"
      end
    end
    run_in_parallel("study_information") do
      Study.find_in_batches(:include => :study_metadata) do |group|
        group.each do |study|
          study.samples.each do |sample|
            StudySampleReport.create(:study_id => study.id, :sample_id => sample.id)
            #@log.debug "<StudySampleReport> :sample => '#{sample.id}', :study => '#{study.id}'"
          end


            if study.study_metadata.study_type
              StudyInformation.create(
                :study_id   => study.id,
                :study_name => study.name,
                :param      => 'study_study_type',
                :param_name => 'Study Type',
                :value      => study.study_metadata.study_type.try(:name)
              )
            end
            if study.study_metadata.reference_genome
              StudyInformation.create(
                :study_id   => study.id,
                :study_name => study.name,
                :param      => 'reference_genome',
                :param_name => 'Reference Genome',
                :value      => study.study_metadata.reference_genome.try(:name)
              )
            end
            if study.study_metadata.data_release_study_type
              StudyInformation.create(
                :study_id   => study.id,
                :study_name => study.name,
                :param      => 'data_release_study_type',
                :param_name => 'Data Release Study Type',
                :value      => study.study_metadata.data_release_study_type.try(:name)
              )
            end
            if study.study_metadata.faculty_sponsor
              StudyInformation.create(
                :study_id   => study.id,
                :study_name => study.name,
                :param      => 'sac_sponsor',
                :param_name => 'Faculty Sponsor',
                :value      => study.study_metadata.faculty_sponsor.try(:name)
              )
            end

          Study::Metadata.attribute_details.each do |attribute|
            StudyInformation.create(
              :study_id   => study.id,
              :study_name => study.name,
              :param      => attribute.name.to_s,
              :param_name => attribute.to_field_info.display_name,
              :value      => study.study_metadata[attribute.name]
            )
            #@log.debug "<StudyInformation> :property => '#{attribute.name}'"
          end
          break if ENV['TEST_RUN']
        end
      end
    end
    run_in_parallel("project_information") do
      Project.find_each(:include => :project_metadata) do |project|
        Project::Metadata.attribute_details.each do |attribute|
          ProjectInformation.create(
            :project_id   => project.id,
            :project_name => project.name,
            :param        => attribute.name.to_s,
            :param_name   => attribute.to_field_info.display_name,
            :value        => project.project_metadata[attribute.name]
          )
          break if ENV['TEST_RUN']
        end
      end
    end
    run_in_parallel("library_tube") do
      LibraryTube.find_in_batches(:include => [:source_request]) do |group|
        stuffing = []
        group.each do |library_tube|
          if library_tube.source_request
            stuffing << {
              :item_id => library_tube.source_request.item_id,
              :asset_id => library_tube.id
            }
          end
        end
        batch_load(ItemIdMapping, stuffing)
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("sample_tube") do
      SampleTube.find_in_batches(:include => :sample) do |group|
        stuffing = []
        group.each do |sample_tube|
          if sample_tube.sample
            stuffing << {
              :sample_id => sample_tube.sample.id,
              :asset_id => sample_tube.id
            }
          end
        end
        batch_load(SampleIdMapping, stuffing)
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("asset_link") do
      AssetLink.find_in_batches do |group|
        stuffing = []
        group.each do |asset_link|
          stuffing << {
            :parent_id => asset_link.ancestor_id,
            :child_id => asset_link.descendant_id
          }
        end
        batch_load(MbAssetLinks, stuffing)
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("item_information") do
      Item.find_in_batches(:batch_size=>200) do |group|
        stuffing = []
        group.each do |item|
          r = item.requests.select {|ir| ir.request_type.present? }.first
          if r.present?
            r.request_metadata.class.attribute_details.each do |attribute|
              stuffing << {
                :item_id    => item.id,
                :item_name  => item.name,
                :param      => attribute.name.to_s,
                :param_name => attribute.to_field_info.display_name,
                :value      => r.request_metadata[attribute.name]
              }
              #Rails.logger.debug "<ItemInformation> :property => '#{attribute.name}', :item => '#{item.id}'"
            end
          end
        end
        batch_load(ItemInformation, stuffing)
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("asset_information") do
      Request.find_in_batches(:include => [:request_metadata, :asset]) do |group|
        stuffing = []
        group.each do |r|
          if r.asset
            r.request_metadata.class.attribute_details.each do |attribute|
              stuffing << {
                :item_id    => r.asset_id,
                :item_name  => r.asset.name,
                :param      => attribute.name.to_s,
                :param_name => attribute.to_field_info.display_name,
                :value      => r.request_metadata[attribute.name]
              }
              #Rails.logger.debug "<AssetInformation> :property => '#{attribute.name}', :item => '#{r.id}'"
            end
          end
        end
        batch_load(AssetInformation, stuffing)
        break if ENV['TEST_RUN']
      end
    end
    run_in_parallel("quota") do
      Quota.find_each(:include => :request_type) do |quota|
        if quota.request_type
          MbQuota.create(
          :project_id => quota.project_id,
          :request_type => quota.request_type.name,
          :quota_limit => quota.limit)
          break if ENV['TEST_RUN']
        end
      end
    end
  end

  def self.switch_loading_to_live
    Script.switch_tables(LOADING_SUFFIX, "", LAST_VERSION_SUFFIX)
  end

  def self.switch_last_version_to_live
    Script.switch_tables(LAST_VERSION_SUFFIX, "", LOADING_SUFFIX)
  end

  # Drop & rename all tables in TABLE_NAMES by a rightward rotation.
  # All tables with the last suffix are dropped.  All tables with the
  # first suffix should exist.
  def self.switch_tables(*sfx)
    on_db WAREHOUSE_DB_CONF do
      TABLE_NAMES.each do |table_name|
        dropname = "#{ table_name }#{ sfx.last }"
        begin
          drop_table dropname.to_sym
          @log.debug "<SwitchTables> dropped #{dropname}"
        rescue
          # Assume it's "table does not exist".  If it is another
          # problem we're likely to find out soon enough.
        end
      end
      TABLE_NAMES.each do |table_name|
        # for(i=sfx.length-2; i>=0; i--)
        (0 .. sfx.length-2).to_a.reverse.each do |i|
          names = [ "#{table_name}#{ sfx[i] }", "#{table_name}#{ sfx[i+1] }" ]
          begin
            rename_table names[0].to_sym, names[1].to_sym
            @log.debug "<SwitchTables> renamed #{ names[0] } to #{ names[1] }"
          rescue
            # Probably another "table does not exist".  If there is a
            # real problem, including first suffix's table being
            # absent, then tough.
          end
        end
      end
    end
  end

  def self.create_table_indexes
    on_db WAREHOUSE_DB_CONF do
      add_index(:"requests#{LOADING_SUFFIX}", :request_id)
      add_index(:"requests#{LOADING_SUFFIX}", :project_id)
      add_index(:"requests#{LOADING_SUFFIX}", :study_id)
      add_index(:"requests#{LOADING_SUFFIX}", :item_id)
      add_index(:"requests#{LOADING_SUFFIX}", :sample_id)

      add_index(:"requests_new#{LOADING_SUFFIX}", :request_id)
      add_index(:"requests_new#{LOADING_SUFFIX}", :project_id)
      add_index(:"requests_new#{LOADING_SUFFIX}", :study_id)
      add_index(:"requests_new#{LOADING_SUFFIX}", :item_id)
      add_index(:"requests_new#{LOADING_SUFFIX}", :sample_id)

      add_index(:"study_sample_reports#{LOADING_SUFFIX}", :study_id)
      add_index(:"study_sample_reports#{LOADING_SUFFIX}", :sample_id)
      add_index(:"project_information#{LOADING_SUFFIX}", :project_id)
      add_index(:"study_information#{LOADING_SUFFIX}", :study_id)
      add_index(:"samples#{LOADING_SUFFIX}", :sample_id)
      add_index(:"item_information#{LOADING_SUFFIX}", :item_id)
      add_index(:"property_information#{LOADING_SUFFIX}", :obj_id)
      add_index(:"property_information#{LOADING_SUFFIX}", :key)

      add_index :"new_billing#{LOADING_SUFFIX}", :project_id
      add_index :"new_billing#{LOADING_SUFFIX}", :cost_code
      add_index :"new_billing#{LOADING_SUFFIX}", :reference
      add_index :"new_billing#{LOADING_SUFFIX}", :description
      add_index :"new_billing#{LOADING_SUFFIX}", :entry_date
      add_index :"new_billing#{LOADING_SUFFIX}", :kind
      add_index :"new_billing#{LOADING_SUFFIX}", :division
      add_index :"new_billing#{LOADING_SUFFIX}", :library_type

      add_index :"library#{LOADING_SUFFIX}", :asset_id
      add_index :"library#{LOADING_SUFFIX}", :batch_created_at
      add_index :"library#{LOADING_SUFFIX}", :batch_id
      add_index :"library#{LOADING_SUFFIX}", [:batch_id, :item_id]
      add_index :"library#{LOADING_SUFFIX}", :item_id
      add_index :"library#{LOADING_SUFFIX}", :position
      add_index :"library#{LOADING_SUFFIX}", :request_id
      add_index :"library#{LOADING_SUFFIX}", :sample_id
      add_index :"library_information#{LOADING_SUFFIX}", :asset_id
      add_index :"library_information#{LOADING_SUFFIX}", :batch_id
      add_index :"library_information#{LOADING_SUFFIX}", :item_id
      add_index :"library_information#{LOADING_SUFFIX}", :target_asset_id

      add_index :"assets#{LOADING_SUFFIX}", :asset_id
      add_index :"assets#{LOADING_SUFFIX}", [:asset_id, :external_release, :asset_type], {:name => 'index_assets_on_asset_id_and_external_release_and_asset_type'}

      add_index :"asset_links#{LOADING_SUFFIX}", :parent_id
      add_index :"asset_links#{LOADING_SUFFIX}", :child_id

      add_index :"multiplex_information#{LOADING_SUFFIX}", :batch_id
      add_index :"multiplex_information#{LOADING_SUFFIX}", :asset_id

    end
  end

  def self.create_tables
    opts = { :id => false, :force => true, :options => "ENGINE #{TABLE_TYPE}" }
    on_db WAREHOUSE_DB_CONF do
      create_table ApiVersion.table_name, opts.clone do |t|
        t.string :version
      end

      create_table NewBilling.table_name, opts.clone do |t|
        t.integer :project_id, :billing_event_id, :price, :request_id
        t.string :division, :project_name, :cost_code, :kind, :description, :quantity, :created_by, :reference, :library_type
        t.datetime :entry_date
        t.timestamps
      end

      create_table ProjectInformation.table_name, opts.clone do |t|
        t.integer :project_id
        t.string :project_name, :param, :param_name
        t.text   :value
      end

      create_table StudyInformation.table_name, opts.clone do |t|
        t.integer :study_id
        t.string :study_name, :param, :param_name
        t.text   :value
      end

      create_table ItemInformation.table_name, opts.clone do |t|
        t.integer :item_id
        t.string :item_name, :param, :param_name, :value
      end

      create_table AssetInformation.table_name, opts.clone do |t|
        t.integer :asset_id
        t.string :asset_name, :param, :param_name, :value
      end

      create_table MbRequest.table_name, opts.clone do |t|
        t.integer :request_id, :project_id, :item_id, :closed, :sample_id, :study_id
        t.string :project_name, :item_name, :sample_name, :type, :state, :read_length
        t.timestamps
      end

      create_table MbRequestNew.table_name, opts.clone do |t|
        t.integer :request_id, :project_id, :item_id, :asset_id, :target_asset_id, :closed, :sample_id, :study_id
        t.string :project_name, :item_name, :sample_name, :type, :state, :read_length
        t.timestamps
      end

      create_table MbQuota.table_name, opts.clone do |t|
        t.integer :quota_limit, :project_id
        t.string :request_type
      end

      create_table MbSample.table_name, opts.clone do |t|
        t.integer :sample_id
        t.string :name
      end

      create_table StudySampleReport.table_name, opts.clone do |t|
        t.integer :study_id, :sample_id
      end

      create_table PropertyInformation.table_name, opts.clone do |t|
        t.string :obj_id, :obj_type, :key
        t.text   :value
      end

      # create_table SequencingSummary.table_name, opts.clone do |t|
      #   t.integer :project?study?_id, :sample_id
      #   t.string :sample_name, :item_id, :library_name, :qc_state, :frag_from, :frag_to, :lib_type
      # end

      create_table Library.table_name, opts.clone do |t|
        t.integer :item_id, :asset_id, :request_id, :batch_id, :position, :sample_id, :pipeline_id
        t.text :name, :batch_state, :qc_state
        t.string :user_login, :asset_type
        t.datetime :created_at,:state_date, :batch_created_at
      end

      create_table MbAsset.table_name, opts.clone do |t|
        t.integer :asset_id, :external_release
        t.text :name
        t.string :asset_type, :public_name, :location, :qc_state
        t.decimal :volume, :precision => 5, :scale => 2
        t.decimal :concentration, :precision => 5, :scale => 2
        t.datetime :created_at, :state_date, :batch_created_at, :scanned_date
      end

      create_table LibraryInformation.table_name, opts.clone do |t|
        t.integer :item_id, :batch_id, :asset_id,:target_asset_id
        t.text :description, :param, :value
      end

      create_table MultiplexInformation.table_name, opts.clone do |t|
        t.integer :batch_id, :asset_id, :sample_id, :tag_id, :tag_group_id, :position, :library_asset_id
        t.string :pool_name, :sequence
      end

      create_table ItemIdMapping.table_name, opts.clone do |t|
        t.integer :item_id, :asset_id
      end

      create_table SampleIdMapping.table_name, opts.clone do |t|
        t.integer :sample_id, :asset_id
      end

      create_table MbAssetLinks.table_name, opts.clone do |t|
        t.integer :parent_id, :child_id
      end

      MODELS.each { |m| m.reset_column_information }
    end
  end

  def self.batch_load(model_class, batch) # Should we be extending AR instead?
    model_class.import(model_class.column_names, batch.map {|row| model_class.column_names.map {|col| row[col.to_sym] } })
  end

  # Administrivia
  def self.commence
    TimeKeeping.start!
    custom_log("sequencescape")
  end

  def self.desist
    TimeKeeping.finish!
    @log.info "Running time is: #{TimeKeeping.running_time}"
  end
end


Script.say_with_time "Starting..." do
  Script.commence
  Script.create_tables

  # These #run_* and their index creation could usefully run in
  # parallel, e.g. by subprocess or if we dared to fork()
  #  -We do.
  Script.run_all_steps

  final_wait

  Script.create_table_indexes

  Script.switch_loading_to_live
  Script.desist
end
