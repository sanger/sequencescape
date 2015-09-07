# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150902112414) do

  create_table "aliquot_indices", :force => true do |t|
    t.integer  "aliquot_id",    :null => false
    t.integer  "lane_id",       :null => false
    t.integer  "aliquot_index", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "aliquot_indices", ["aliquot_id"], :name => "index_aliquot_indices_on_aliquot_id", :unique => true
  add_index "aliquot_indices", ["lane_id", "aliquot_index"], :name => "index_aliquot_indices_on_lane_id_and_aliquot_index", :unique => true

  create_table "aliquots", :force => true do |t|
    t.integer  "receptacle_id",                    :null => false
    t.integer  "study_id"
    t.integer  "project_id"
    t.integer  "library_id"
    t.integer  "sample_id",                        :null => false
    t.integer  "tag_id"
    t.string   "library_type"
    t.integer  "insert_size_from"
    t.integer  "insert_size_to"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bait_library_id"
    t.integer  "tag2_id",          :default => -1, :null => false
  end

  add_index "aliquots", ["receptacle_id", "tag_id", "tag2_id"], :name => "aliquot_tags_and_tag2s_are_unique_within_receptacle", :unique => true
  add_index "aliquots", ["sample_id"], :name => "index_aliquots_on_sample_id"
  add_index "aliquots", ["study_id"], :name => "index_aliquots_on_study_id"
  add_index "aliquots", ["tag_id"], :name => "tag_id_idx"

  create_table "api_applications", :force => true do |t|
    t.string "name",        :null => false
    t.string "key",         :null => false
    t.string "contact",     :null => false
    t.text   "description"
    t.string "privilege",   :null => false
  end

  add_index "api_applications", ["key"], :name => "index_api_applications_on_key"

  create_table "archived_properties", :force => true do |t|
    t.text    "value"
    t.string  "propertied_type"
    t.integer "user_id"
    t.string  "key",             :limit => 50
    t.integer "propertied_id"
  end

  create_table "asset_audits", :force => true do |t|
    t.string   "message"
    t.string   "key"
    t.string   "created_by"
    t.integer  "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "witnessed_by"
  end

  add_index "asset_audits", ["asset_id"], :name => "index_asset_audits_on_asset_id"

  create_table "asset_barcodes", :force => true do |t|
  end

  create_table "asset_creation_parents", :force => true do |t|
    t.integer  "asset_creation_id"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "asset_creations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "parent_id"
    t.integer  "child_purpose_id"
    t.integer  "child_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",             :null => false
  end

  create_table "asset_group_assets", :force => true do |t|
    t.integer  "asset_id"
    t.integer  "asset_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "asset_group_assets", ["asset_group_id"], :name => "index_asset_group_assets_on_asset_group_id"
  add_index "asset_group_assets", ["asset_id"], :name => "index_asset_group_assets_on_asset_id"

  create_table "asset_groups", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "asset_links", :force => true do |t|
    t.integer  "ancestor_id"
    t.integer  "descendant_id"
    t.boolean  "direct"
    t.integer  "count"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "asset_links", ["ancestor_id", "direct"], :name => "index_asset_links_on_ancestor_id_and_direct"
  add_index "asset_links", ["descendant_id", "direct"], :name => "index_asset_links_on_descendant_id_and_direct"

  create_table "asset_shapes", :force => true do |t|
    t.string   "name",                 :null => false
    t.integer  "horizontal_ratio",     :null => false
    t.integer  "vertical_ratio",       :null => false
    t.string   "description_strategy", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.text     "descriptors"
    t.text     "descriptor_fields"
    t.string   "sti_type",                :limit => 50
    t.string   "barcode"
    t.string   "qc_state",                :limit => 20
    t.boolean  "resource"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "map_id"
    t.integer  "size"
    t.boolean  "closed",                                                               :default => false
    t.string   "public_name"
    t.boolean  "archive"
    t.boolean  "external_release"
    t.string   "two_dimensional_barcode"
    t.integer  "plate_purpose_id"
    t.decimal  "volume",                                :precision => 10, :scale => 2
    t.integer  "barcode_prefix_id"
    t.decimal  "concentration",                         :precision => 18, :scale => 8
    t.integer  "legacy_sample_id"
    t.integer  "legacy_tag_id"
  end

  add_index "assets", ["barcode"], :name => "index_assets_on_barcode"
  add_index "assets", ["barcode_prefix_id"], :name => "index_assets_on_barcode_prefix_id"
  add_index "assets", ["legacy_sample_id"], :name => "index_assets_on_sample_id"
  add_index "assets", ["map_id"], :name => "index_assets_on_map_id"
  add_index "assets", ["sti_type", "plate_purpose_id"], :name => "index_assets_on_plate_purpose_id_sti_type"
  add_index "assets", ["sti_type", "updated_at"], :name => "index_assets_on_sti_type_and_updated_at"
  add_index "assets", ["sti_type"], :name => "index_assets_on_sti_type"
  add_index "assets", ["updated_at"], :name => "index_assets_on_updated_at"

  create_table "attachments", :force => true do |t|
    t.integer "pipeline_workflow_id"
    t.integer "attachable_id"
    t.string  "attachable_type",      :limit => 50
    t.integer "position"
  end

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",        :default => 0
    t.datetime "created_at"
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "bait_libraries", :force => true do |t|
    t.integer  "bait_library_supplier_id"
    t.string   "name",                                       :null => false
    t.string   "supplier_identifier"
    t.string   "target_species",                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bait_library_type_id",                       :null => false
    t.boolean  "visible",                  :default => true, :null => false
  end

  add_index "bait_libraries", ["bait_library_supplier_id", "name"], :name => "bait_library_names_are_unique_within_a_supplier", :unique => true

  create_table "bait_library_layouts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "plate_id",                   :null => false
    t.string   "layout",     :limit => 1024
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bait_library_layouts", ["plate_id"], :name => "bait_libraries_are_laid_out_on_a_plate_once", :unique => true

  create_table "bait_library_suppliers", :force => true do |t|
    t.string   "name",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",    :default => true, :null => false
  end

  add_index "bait_library_suppliers", ["name"], :name => "index_bait_library_suppliers_on_name", :unique => true

  create_table "bait_library_types", :force => true do |t|
    t.string   "name",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",    :default => true, :null => false
  end

  add_index "bait_library_types", ["name"], :name => "index_bait_library_types_on_name", :unique => true

  create_table "barcode_prefixes", :force => true do |t|
    t.string "prefix", :limit => 3
  end

  add_index "barcode_prefixes", ["prefix"], :name => "index_barcode_prefixes_on_prefix"

  create_table "barcode_printer_types", :force => true do |t|
    t.string   "name"
    t.integer  "printer_type_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "barcode_printer_types", ["name"], :name => "index_barcode_printer_types_on_name"
  add_index "barcode_printer_types", ["printer_type_id"], :name => "index_barcode_printer_types_on_printer_type_id"
  add_index "barcode_printer_types", ["type"], :name => "index_barcode_printer_types_on_type"

  create_table "barcode_printers", :force => true do |t|
    t.string   "name"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "barcode_printer_type_id"
  end

  create_table "batch_requests", :force => true do |t|
    t.integer  "batch_id",   :null => false
    t.integer  "request_id", :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "batch_requests", ["batch_id"], :name => "index_batch_requests_on_batch_id"
  add_index "batch_requests", ["request_id"], :name => "index_batch_requests_on_request_id"
  add_index "batch_requests", ["request_id"], :name => "request_id", :unique => true
  add_index "batch_requests", ["updated_at"], :name => "index_batch_requests_on_updated_at"

  create_table "batches", :force => true do |t|
    t.integer  "item_limit"
    t.datetime "created_at"
    t.integer  "user_id"
    t.datetime "updated_at"
    t.integer  "pipeline_id"
    t.string   "state",            :limit => 20
    t.integer  "assignee_id"
    t.integer  "qc_pipeline_id"
    t.string   "production_state"
    t.string   "qc_state",         :limit => 25
    t.string   "barcode"
  end

  add_index "batches", ["pipeline_id", "state", "created_at"], :name => "index_batches_on_pipeline_id_and_state_and_created_at"
  add_index "batches", ["updated_at"], :name => "index_batches_on_updated_at"

  create_table "billing_events", :force => true do |t|
    t.string   "kind",        :default => "charge",      :null => false
    t.datetime "entry_date",                             :null => false
    t.string   "created_by",                             :null => false
    t.integer  "project_id",                             :null => false
    t.string   "reference",                              :null => false
    t.string   "description", :default => "Unspecified"
    t.float    "quantity",    :default => 1.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_id",                             :null => false
  end

  add_index "billing_events", ["kind"], :name => "index_billing_events_on_kind"
  add_index "billing_events", ["reference"], :name => "index_billing_events_on_reference"

  create_table "broadcast_events", :force => true do |t|
    t.string   "sti_type"
    t.string   "seed_type"
    t.integer  "seed_id"
    t.integer  "user_id"
    t.text     "properties"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "budget_divisions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bulk_transfers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "comments", :force => true do |t|
    t.string   "title"
    t.string   "commentable_type", :limit => 50
    t.integer  "user_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "commentable_id",                 :null => false
  end

  add_index "comments", ["commentable_id", "commentable_type"], :name => "index_comments_on_commentable_id_and_commentable_type"

  create_table "container_associations", :force => true do |t|
    t.integer "container_id", :null => false
    t.integer "content_id",   :null => false
  end

  add_index "container_associations", ["container_id"], :name => "index_container_associations_on_container_id"
  add_index "container_associations", ["content_id"], :name => "container_association_content_is_unique", :unique => true

  create_table "controls", :force => true do |t|
    t.string   "name"
    t.integer  "item_id"
    t.integer  "pipeline_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_texts", :force => true do |t|
    t.string   "identifier"
    t.integer  "differential"
    t.string   "content_type"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_release_study_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "for_array_express", :default => false
    t.boolean  "is_default",        :default => false
    t.boolean  "is_assay_type",     :default => false
  end

  create_table "db_files", :force => true do |t|
    t.binary  "data",                :limit => 2147483647
    t.integer "owner_id"
    t.string  "owner_type",          :limit => 25,         :default => "Document", :null => false
    t.string  "owner_type_extended"
  end

  add_index "db_files", ["owner_type", "owner_id"], :name => "index_db_files_on_owner_type_and_owner_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "depricated_attempts", :force => true do |t|
    t.string   "state",       :limit => 20, :default => "pending"
    t.integer  "request_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "workflow_id"
  end

  add_index "depricated_attempts", ["request_id"], :name => "index_attempts_on_request_id"

  create_table "descriptors", :force => true do |t|
    t.string  "name"
    t.string  "value"
    t.text    "selection"
    t.integer "task_id"
    t.string  "kind"
    t.boolean "required"
    t.integer "sorter"
    t.integer "family_id"
    t.string  "key",       :limit => 50
  end

  add_index "descriptors", ["task_id"], :name => "index_descriptors_on_task_id"

  create_table "documents", :force => true do |t|
    t.integer "documentable_id"
    t.integer "size"
    t.string  "content_type"
    t.string  "filename"
    t.integer "height"
    t.integer "width"
    t.integer "parent_id"
    t.string  "thumbnail"
    t.integer "db_file_id"
    t.string  "documentable_type",     :limit => 50, :null => false
    t.string  "documentable_extended", :limit => 50
  end

  add_index "documents", ["documentable_id", "documentable_type"], :name => "index_documents_on_documentable_id_and_documentable_type"
  add_index "documents", ["documentable_type", "documentable_id"], :name => "index_documents_on_documentable_type_and_documentable_id"

  create_table "documents_shadow", :force => true do |t|
    t.integer "documentable_id"
    t.integer "size"
    t.string  "content_type"
    t.string  "filename"
    t.integer "height"
    t.integer "width"
    t.integer "parent_id"
    t.string  "thumbnail"
    t.integer "db_file_id"
    t.string  "documentable_type", :limit => 50
  end

  add_index "documents_shadow", ["documentable_id", "documentable_type"], :name => "index_documents_on_documentable_id_and_documentable_type"

  create_table "equipment", :force => true do |t|
    t.string "name"
    t.string "equipment_type"
    t.string "prefix",         :limit => 2,  :null => false
    t.string "ean13_barcode",  :limit => 13
  end

  create_table "events", :force => true do |t|
    t.integer  "eventful_id"
    t.string   "eventful_type",  :limit => 50
    t.string   "message"
    t.string   "family"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "identifier"
    t.string   "location"
    t.boolean  "actioned"
    t.text     "content"
    t.string   "created_by"
    t.string   "of_interest_to"
    t.string   "descriptor_key", :limit => 50
    t.string   "type",                         :default => "Event"
  end

  add_index "events", ["eventful_id"], :name => "index_events_on_eventful_id"
  add_index "events", ["eventful_type"], :name => "index_events_on_eventful_type"
  add_index "events", ["family"], :name => "index_events_on_family"

  create_table "extended_validators", :force => true do |t|
    t.string   "behaviour",  :null => false
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_properties", :force => true do |t|
    t.integer  "propertied_id"
    t.string   "propertied_type", :limit => 50
    t.string   "key",             :limit => 50
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_properties", ["propertied_id", "propertied_type", "key"], :name => "ep_pi_pt_key"
  add_index "external_properties", ["propertied_id", "propertied_type"], :name => "ep_pi_pt"
  add_index "external_properties", ["propertied_type", "key"], :name => "index_external_properties_on_propertied_type_and_key"
  add_index "external_properties", ["value"], :name => "index_external_properties_on_value"

  create_table "faculty_sponsors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "failures", :force => true do |t|
    t.integer  "failable_id"
    t.string   "failable_type", :limit => 50
    t.text     "reason"
    t.boolean  "notify_remote"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
  end

  add_index "failures", ["failable_id"], :name => "index_failures_on_failable_id"

  create_table "families", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.string  "relates_to"
    t.integer "task_id"
    t.integer "pipeline_workflow_id"
  end

  create_table "identifiers", :force => true do |t|
    t.integer "identifiable_id"
    t.string  "identifiable_type", :limit => 50
    t.string  "resource_name"
    t.integer "external_id"
    t.string  "external_type",     :limit => 50
    t.boolean "do_not_sync",                     :default => false
  end

  add_index "identifiers", ["external_id", "identifiable_id"], :name => "index_identifiers_on_external_id_and_identifiable_id"
  add_index "identifiers", ["external_type"], :name => "index_identifiers_on_external_type"
  add_index "identifiers", ["identifiable_id", "identifiable_type"], :name => "index_identifiers_on_identifiable_id_and_identifiable_type"
  add_index "identifiers", ["resource_name"], :name => "index_identifiers_on_resource_name"

  create_table "implements", :force => true do |t|
    t.string "name"
    t.string "barcode"
    t.string "equipment_type"
  end

  add_index "implements", ["barcode"], :name => "index_implements_on_barcode"

  create_table "items", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "study_id"
    t.integer  "user_id"
    t.integer  "count"
    t.integer  "workflow_sample_id"
    t.boolean  "closed",             :default => false
    t.integer  "pool_id"
    t.integer  "workflow_id"
    t.integer  "version"
    t.integer  "submission_id"
  end

  add_index "items", ["name"], :name => "index_items_on_name"
  add_index "items", ["study_id"], :name => "index_items_on_study_id"
  add_index "items", ["submission_id"], :name => "index_items_on_submission_id"
  add_index "items", ["version"], :name => "index_items_on_version"
  add_index "items", ["workflow_id"], :name => "index_items_on_workflow_id"
  add_index "items", ["workflow_sample_id"], :name => "index_items_on_sample_id"

  create_table "lab_events", :force => true do |t|
    t.text     "description"
    t.text     "descriptors"
    t.text     "descriptor_fields"
    t.integer  "eventful_id"
    t.string   "eventful_type",     :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename"
    t.binary   "data"
    t.text     "message"
    t.integer  "user_id"
    t.integer  "batch_id"
  end

  add_index "lab_events", ["batch_id"], :name => "index_lab_events_on_batch_id"
  add_index "lab_events", ["created_at"], :name => "index_lab_events_on_created_at"
  add_index "lab_events", ["description", "eventful_type"], :name => "index_lab_events_find_flowcell", :length => {"description"=>20, "eventful_type"=>nil}
  add_index "lab_events", ["eventful_id"], :name => "index_lab_events_on_eventful_id"
  add_index "lab_events", ["eventful_type"], :name => "index_lab_events_on_eventful_type"

  create_table "lab_interface_workflows", :force => true do |t|
    t.string  "name"
    t.integer "item_limit"
    t.text    "locale"
    t.integer "pipeline_id"
  end

  add_index "lab_interface_workflows", ["pipeline_id"], :name => "index_lab_interface_workflows_on_pipeline_id"

  create_table "lane_metadata", :force => true do |t|
    t.integer  "lane_id"
    t.string   "release_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "library_types", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "library_types_request_types", :force => true do |t|
    t.integer  "request_type_id",                    :null => false
    t.integer  "library_type_id",                    :null => false
    t.boolean  "is_default",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "library_types_request_types", ["library_type_id"], :name => "fk_library_types_request_types_to_library_types"
  add_index "library_types_request_types", ["request_type_id"], :name => "fk_library_types_request_types_to_request_types"

  create_table "location_associations", :force => true do |t|
    t.integer "locatable_id", :null => false
    t.integer "location_id",  :null => false
  end

  add_index "location_associations", ["locatable_id"], :name => "single_location_per_locatable_idx", :unique => true
  add_index "location_associations", ["location_id"], :name => "index_location_associations_on_location_id"

  create_table "locations", :force => true do |t|
    t.string "name"
  end

  create_table "lot_types", :force => true do |t|
    t.string   "name",              :null => false
    t.string   "template_class",    :null => false
    t.integer  "target_purpose_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lot_types", ["target_purpose_id"], :name => "fk_lot_types_to_plate_purposes"

  create_table "lots", :force => true do |t|
    t.string   "lot_number",    :null => false
    t.integer  "lot_type_id",   :null => false
    t.integer  "template_id",   :null => false
    t.string   "template_type", :null => false
    t.integer  "user_id",       :null => false
    t.date     "received_at",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lots", ["lot_number", "lot_type_id"], :name => "index_lot_number_lot_type_id", :unique => true
  add_index "lots", ["lot_type_id"], :name => "fk_lots_to_lot_types"

  create_table "maps", :force => true do |t|
    t.string  "description",    :limit => 4
    t.integer "asset_size"
    t.integer "location_id"
    t.integer "row_order"
    t.integer "column_order"
    t.integer "asset_shape_id",              :default => 1, :null => false
  end

  add_index "maps", ["description", "asset_size"], :name => "index_maps_on_description_and_asset_size"
  add_index "maps", ["description"], :name => "index_maps_on_description"

  create_table "messenger_creators", :force => true do |t|
    t.string   "template",   :null => false
    t.string   "root",       :null => false
    t.integer  "purpose_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messenger_creators", ["purpose_id"], :name => "fk_messenger_creators_to_plate_purposes"

  create_table "messengers", :force => true do |t|
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "root",        :null => false
    t.string   "template",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_roles", :force => true do |t|
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", :force => true do |t|
    t.integer  "study_id"
    t.integer  "workflow_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state_to_delete",   :limit => 20
    t.string   "message_to_delete"
    t.integer  "user_id"
    t.text     "item_options"
    t.text     "request_types"
    t.text     "request_options"
    t.text     "comments"
    t.integer  "project_id"
    t.string   "sti_type"
    t.string   "template_name"
    t.integer  "asset_group_id"
    t.string   "asset_group_name"
    t.integer  "submission_id"
    t.integer  "pre_cap_group"
    t.integer  "order_role_id"
  end

  add_index "orders", ["state_to_delete"], :name => "index_submissions_on_state"
  add_index "orders", ["study_id"], :name => "index_submissions_on_project_id"

  create_table "pac_bio_library_tube_metadata", :force => true do |t|
    t.integer  "smrt_cells_available"
    t.string   "prep_kit_barcode"
    t.string   "binding_kit_barcode"
    t.string   "movie_length"
    t.integer  "pac_bio_library_tube_id"
    t.string   "protocol"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pac_bio_library_tube_metadata", ["pac_bio_library_tube_id"], :name => "index_pac_bio_library_tube_metadata_on_pac_bio_library_tube_id"

  create_table "permissions", :force => true do |t|
    t.string   "role_name"
    t.string   "name"
    t.string   "permissable_type", :limit => 50
    t.integer  "permissable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["permissable_id"], :name => "index_permissions_on_permissable_id"

  create_table "pipeline_request_information_types", :force => true do |t|
    t.integer  "pipeline_id"
    t.integer  "request_information_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pipelines", :force => true do |t|
    t.string   "name"
    t.boolean  "automated"
    t.boolean  "active",                                      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "next_pipeline_id"
    t.integer  "previous_pipeline_id"
    t.integer  "location_id"
    t.boolean  "group_by_parent"
    t.string   "asset_type",                    :limit => 50
    t.boolean  "group_by_submission_to_delete"
    t.boolean  "multiplexed"
    t.string   "sti_type",                      :limit => 50
    t.integer  "sorter"
    t.boolean  "paginate",                                    :default => false
    t.integer  "max_size"
    t.boolean  "summary",                                     :default => true
    t.boolean  "group_by_study_to_delete",                    :default => true
    t.integer  "max_number_of_groups"
    t.boolean  "externally_managed",                          :default => false
    t.string   "group_name"
    t.integer  "control_request_type_id",                                        :null => false
    t.integer  "min_size"
  end

  add_index "pipelines", ["sorter"], :name => "index_pipelines_on_sorter"

  create_table "pipelines_request_types", :force => true do |t|
    t.integer "pipeline_id",     :null => false
    t.integer "request_type_id", :null => false
  end

  add_index "pipelines_request_types", ["pipeline_id"], :name => "fk_pipelines_request_types_to_pipelines"
  add_index "pipelines_request_types", ["request_type_id"], :name => "fk_pipelines_request_types_to_request_types"

  create_table "plate_conversions", :force => true do |t|
    t.integer  "target_id",  :null => false
    t.integer  "purpose_id", :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "plate_creator_purposes", :force => true do |t|
    t.integer  "plate_creator_id",  :null => false
    t.integer  "plate_purpose_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_purpose_id"
  end

  create_table "plate_creators", :force => true do |t|
    t.string   "name",             :null => false
    t.integer  "plate_purpose_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plate_creators", ["name"], :name => "index_plate_creators_on_name", :unique => true

  create_table "plate_metadata", :force => true do |t|
    t.integer  "plate_id"
    t.string   "infinium_barcode"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fluidigm_barcode", :limit => 10
  end

  add_index "plate_metadata", ["fluidigm_barcode"], :name => "index_on_fluidigm_barcode", :unique => true
  add_index "plate_metadata", ["plate_id"], :name => "index_plate_metadata_on_plate_id"

  create_table "plate_owners", :force => true do |t|
    t.integer  "user_id",        :null => false
    t.integer  "plate_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "eventable_id",   :null => false
    t.string   "eventable_type", :null => false
  end

  create_table "plate_purpose_relationships", :force => true do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.integer "transfer_request_type_id", :null => false
  end

  create_table "plate_purposes", :force => true do |t|
    t.string   "name",                                                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.string   "target_type",                     :limit => 30
    t.boolean  "qc_display",                                    :default => false
    t.boolean  "pulldown_display"
    t.boolean  "can_be_considered_a_stock_plate",               :default => false,           :null => false
    t.string   "default_state",                                 :default => "pending"
    t.integer  "barcode_printer_type_id",                       :default => 2
    t.boolean  "cherrypickable_target",                         :default => true,            :null => false
    t.boolean  "cherrypickable_source",                         :default => false,           :null => false
    t.string   "cherrypick_direction",                          :default => "column",        :null => false
    t.integer  "default_location_id"
    t.string   "cherrypick_filters"
    t.integer  "size",                                          :default => 96
    t.integer  "asset_shape_id",                                :default => 1,               :null => false
    t.string   "barcode_for_tecan",                             :default => "ean13_barcode", :null => false
    t.integer  "source_purpose_id"
    t.integer  "lifespan"
  end

  add_index "plate_purposes", ["qc_display"], :name => "index_plate_purposes_on_qc_display"
  add_index "plate_purposes", ["target_type"], :name => "index_plate_purposes_on_target_type"
  add_index "plate_purposes", ["type"], :name => "index_plate_purposes_on_type"
  add_index "plate_purposes", ["updated_at"], :name => "index_plate_purposes_on_updated_at"

  create_table "plate_volumes", :force => true do |t|
    t.string   "barcode"
    t.string   "uploaded_file_name"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plate_volumes", ["uploaded_file_name"], :name => "index_plate_volumes_on_uploaded_file_name"

  create_table "pooling_methods", :force => true do |t|
    t.string "pooling_behaviour", :limit => 50, :null => false
    t.text   "pooling_options"
  end

  create_table "pre_capture_pool_pooled_requests", :force => true do |t|
    t.integer "pre_capture_pool_id", :null => false
    t.integer "request_id",          :null => false
  end

  add_index "pre_capture_pool_pooled_requests", ["request_id"], :name => "request_id_should_be_unique", :unique => true

  create_table "pre_capture_pools", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_lines", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "project_managers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_metadata", :force => true do |t|
    t.integer  "project_id"
    t.string   "project_cost_code"
    t.string   "funding_comments"
    t.string   "collaborators"
    t.string   "external_funding_source"
    t.string   "sequencing_budget_cost_centre"
    t.string   "project_funding_model"
    t.string   "gt_committee_tracking_id"
    t.integer  "project_manager_id",            :default => 1
    t.integer  "budget_division_id",            :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_metadata", ["project_id"], :name => "index_project_metadata_on_project_id"

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.boolean  "enforce_quotas",               :default => true
    t.boolean  "approved",                     :default => false
    t.string   "state",          :limit => 20, :default => "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["approved"], :name => "index_projects_on_approved"
  add_index "projects", ["enforce_quotas"], :name => "index_projects_on_enforce_quotas"
  add_index "projects", ["state"], :name => "index_projects_on_state"
  add_index "projects", ["updated_at"], :name => "index_projects_on_updated_at"

  create_table "qc_decision_qcables", :force => true do |t|
    t.integer  "qc_decision_id", :null => false
    t.integer  "qcable_id",      :null => false
    t.string   "decision",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_decisions", :force => true do |t|
    t.integer  "lot_id",     :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_files", :force => true do |t|
    t.integer  "asset_id"
    t.string   "asset_type"
    t.integer  "size"
    t.string   "content_type"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qcable_creators", :force => true do |t|
    t.integer  "lot_id",     :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qcables", :force => true do |t|
    t.integer  "lot_id",            :null => false
    t.integer  "asset_id",          :null => false
    t.string   "state",             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "qcable_creator_id", :null => false
  end

  add_index "qcables", ["asset_id"], :name => "index_asset_id"
  add_index "qcables", ["lot_id"], :name => "index_lot_id"

  create_table "quotas_bkp", :force => true do |t|
    t.integer  "limit",            :default => 0
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_type_id"
    t.integer  "preordered_count", :default => 0
  end

  add_index "quotas_bkp", ["request_type_id", "project_id"], :name => "index_quotas_on_request_type_id_and_project_id"
  add_index "quotas_bkp", ["updated_at"], :name => "index_quotas_on_updated_at"

  create_table "reference_genomes", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_events", :force => true do |t|
    t.integer  "request_id",   :null => false
    t.string   "event_name",   :null => false
    t.string   "from_state"
    t.string   "to_state"
    t.datetime "current_from", :null => false
    t.datetime "current_to"
  end

  add_index "request_events", ["request_id", "current_to"], :name => "index_request_events_on_request_id_and_current_to"

  create_table "request_information_types", :force => true do |t|
    t.string   "name"
    t.string   "key",           :limit => 50
    t.string   "label"
    t.integer  "width"
    t.string   "data_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hide_in_inbox"
  end

  create_table "request_informations", :force => true do |t|
    t.integer  "request_id"
    t.integer  "request_information_type_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "request_informations", ["request_id"], :name => "index_request_informations_on_request_id"

  create_table "request_metadata", :force => true do |t|
    t.integer  "request_id"
    t.string   "name"
    t.string   "tag"
    t.string   "library_type"
    t.string   "fragment_size_required_to"
    t.string   "fragment_size_required_from"
    t.integer  "read_length"
    t.integer  "batch_id"
    t.integer  "pipeline_id"
    t.string   "pass"
    t.string   "failure"
    t.string   "library_creation_complete"
    t.string   "sequencing_type"
    t.integer  "insert_size"
    t.integer  "bait_library_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pre_capture_plex_level"
    t.float    "gigabases_expected"
    t.integer  "target_purpose_id"
    t.boolean  "customer_accepts_responsibility"
  end

  add_index "request_metadata", ["request_id"], :name => "index_request_metadata_on_request_id"

  create_table "request_quotas_bkp", :force => true do |t|
    t.integer "request_id", :null => false
    t.integer "quota_id",   :null => false
  end

  add_index "request_quotas_bkp", ["quota_id", "request_id"], :name => "index_request_quotas_on_quota_id_and_request_id"
  add_index "request_quotas_bkp", ["request_id"], :name => "fk_request_quotas_to_requests"

  create_table "request_type_plate_purposes", :force => true do |t|
    t.integer "request_type_id",  :null => false
    t.integer "plate_purpose_id", :null => false
  end

  add_index "request_type_plate_purposes", ["request_type_id", "plate_purpose_id"], :name => "plate_purposes_are_unique_within_request_type", :unique => true

  create_table "request_type_validators", :force => true do |t|
    t.integer  "request_type_id", :null => false
    t.string   "request_option",  :null => false
    t.text     "valid_options",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_types", :force => true do |t|
    t.string   "key",                :limit => 100
    t.string   "name"
    t.integer  "workflow_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "asset_type"
    t.integer  "order"
    t.string   "initial_state",      :limit => 20
    t.string   "target_asset_type"
    t.boolean  "multiples_allowed",                 :default => false
    t.string   "request_class_name"
    t.text     "request_parameters"
    t.integer  "morphology",                        :default => 0
    t.boolean  "for_multiplexing",                  :default => false
    t.boolean  "billable",                          :default => false
    t.integer  "product_line_id"
    t.boolean  "deprecated",                        :default => false, :null => false
    t.boolean  "no_target_asset",                   :default => false, :null => false
    t.integer  "target_purpose_id"
    t.integer  "pooling_method_id"
  end

  create_table "request_types_extended_validators", :force => true do |t|
    t.integer  "request_type_id",       :null => false
    t.integer  "extended_validator_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "request_types_extended_validators", ["extended_validator_id"], :name => "fk_request_types_extended_validators_to_extended_validators"
  add_index "request_types_extended_validators", ["request_type_id"], :name => "fk_request_types_extended_validators_to_request_types"

  create_table "requests", :force => true do |t|
    t.integer  "initial_study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "state",              :limit => 20, :default => "pending"
    t.integer  "sample_pool_id"
    t.integer  "workflow_id"
    t.integer  "request_type_id"
    t.integer  "item_id"
    t.integer  "asset_id"
    t.integer  "target_asset_id"
    t.integer  "pipeline_id"
    t.integer  "submission_id"
    t.boolean  "charge"
    t.integer  "initial_project_id"
    t.integer  "priority",                         :default => 0
    t.string   "sti_type"
    t.integer  "order_id"
  end

  add_index "requests", ["asset_id"], :name => "index_requests_on_asset_id"
  add_index "requests", ["initial_project_id"], :name => "index_requests_on_project_id"
  add_index "requests", ["initial_study_id", "request_type_id", "state"], :name => "index_requests_on_project_id_and_request_type_id_and_state"
  add_index "requests", ["initial_study_id"], :name => "index_request_on_project_id"
  add_index "requests", ["item_id"], :name => "index_request_on_item_id"
  add_index "requests", ["state", "request_type_id", "initial_study_id"], :name => "request_project_index"
  add_index "requests", ["submission_id"], :name => "index_requests_on_submission_id"
  add_index "requests", ["target_asset_id"], :name => "index_requests_on_target_asset_id"
  add_index "requests", ["updated_at"], :name => "index_requests_on_updated_at"

  create_table "robot_properties", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.string   "key",        :limit => 50
    t.integer  "robot_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "robots", :force => true do |t|
    t.string   "name"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "barcode"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.string   "authorizable_type", :limit => 50
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["authorizable_id", "authorizable_type"], :name => "index_roles_on_authorizable_id_and_authorizable_type"
  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "sample_manifest_templates", :force => true do |t|
    t.string "name"
    t.string "asset_type"
    t.string "path"
    t.string "default_values"
    t.string "cell_map"
  end

  create_table "sample_manifests", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "study_id"
    t.integer  "project_id"
    t.integer  "supplier_id"
    t.integer  "count"
    t.string   "asset_type"
    t.text     "last_errors"
    t.string   "state"
    t.text     "barcodes"
    t.integer  "user_id"
  end

  add_index "sample_manifests", ["asset_type"], :name => "index_sample_manifests_on_asset_type"
  add_index "sample_manifests", ["created_at"], :name => "index_sample_manifests_on_created_at"
  add_index "sample_manifests", ["study_id"], :name => "index_sample_manifests_on_study_id"
  add_index "sample_manifests", ["supplier_id"], :name => "index_sample_manifests_on_supplier_id"
  add_index "sample_manifests", ["updated_at"], :name => "index_sample_manifests_on_updated_at"
  add_index "sample_manifests", ["user_id"], :name => "index_sample_manifests_on_user_id"

  create_table "sample_metadata", :force => true do |t|
    t.integer  "sample_id"
    t.string   "organism"
    t.string   "gc_content"
    t.string   "cohort"
    t.string   "gender"
    t.string   "country_of_origin"
    t.string   "geographical_region"
    t.string   "ethnicity"
    t.string   "dna_source"
    t.string   "volume"
    t.string   "supplier_plate_id"
    t.string   "mother"
    t.string   "father"
    t.string   "replicate"
    t.string   "sample_public_name"
    t.string   "sample_common_name"
    t.string   "sample_strain_att"
    t.integer  "sample_taxon_id"
    t.string   "sample_ebi_accession_number"
    t.string   "sample_sra_hold"
    t.string   "sample_reference_genome_old"
    t.text     "sample_description"
    t.string   "sibling"
    t.boolean  "is_resubmitted"
    t.string   "date_of_sample_collection"
    t.string   "date_of_sample_extraction"
    t.string   "sample_extraction_method"
    t.string   "sample_purified"
    t.string   "purification_method"
    t.string   "concentration"
    t.string   "concentration_determined_by"
    t.string   "sample_type"
    t.string   "sample_storage_conditions"
    t.string   "supplier_name"
    t.integer  "reference_genome_id",         :default => 1
    t.string   "genotype"
    t.string   "phenotype"
    t.string   "age"
    t.string   "developmental_stage"
    t.string   "cell_type"
    t.string   "disease_state"
    t.string   "compound"
    t.string   "dose"
    t.string   "immunoprecipitate"
    t.string   "growth_condition"
    t.string   "rnai"
    t.string   "organism_part"
    t.string   "time_point"
    t.string   "disease"
    t.string   "subject"
    t.string   "treatment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "donor_id"
  end

  add_index "sample_metadata", ["sample_id"], :name => "index_sample_metadata_on_sample_id"
  add_index "sample_metadata", ["supplier_name"], :name => "index_sample_metadata_on_supplier_name"

  create_table "sample_registrars", :force => true do |t|
    t.integer "study_id"
    t.integer "user_id"
    t.integer "sample_id"
    t.integer "sample_tube_id"
    t.integer "asset_group_id"
  end

  create_table "samples", :force => true do |t|
    t.string   "name"
    t.boolean  "new_name_format",            :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sanger_sample_id"
    t.integer  "sample_manifest_id"
    t.boolean  "control"
    t.boolean  "empty_supplier_sample_name", :default => false
    t.boolean  "updated_by_manifest",        :default => false
    t.boolean  "consent_withdrawn",          :default => false, :null => false
  end

  add_index "samples", ["created_at"], :name => "index_samples_on_created_at"
  add_index "samples", ["name"], :name => "index_samples_on_name"
  add_index "samples", ["sample_manifest_id"], :name => "index_samples_on_sample_manifest_id"
  add_index "samples", ["sanger_sample_id"], :name => "index_samples_on_sanger_sample_id"
  add_index "samples", ["updated_at"], :name => "index_samples_on_updated_at"

  create_table "sanger_sample_ids", :force => true do |t|
  end

  create_table "searches", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "model_name"
  end

  create_table "specific_tube_creation_purposes", :force => true do |t|
    t.integer  "specific_tube_creation_id"
    t.integer  "tube_purpose_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stamp_qcables", :force => true do |t|
    t.integer  "stamp_id",   :null => false
    t.integer  "qcable_id",  :null => false
    t.string   "bed",        :null => false
    t.integer  "order",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stamp_qcables", ["qcable_id"], :name => "fk_stamp_qcables_to_qcables"
  add_index "stamp_qcables", ["stamp_id"], :name => "fk_stamp_qcables_to_stamps"

  create_table "stamps", :force => true do |t|
    t.integer  "lot_id",     :null => false
    t.integer  "user_id",    :null => false
    t.integer  "robot_id",   :null => false
    t.string   "tip_lot",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stamps", ["lot_id"], :name => "fk_stamps_to_lots"
  add_index "stamps", ["robot_id"], :name => "fk_stamps_to_robots"
  add_index "stamps", ["user_id"], :name => "fk_stamps_to_users"

  create_table "state_changes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "target_id"
    t.string   "contents",       :limit => 1024
    t.string   "previous_state"
    t.string   "target_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reason"
  end

  create_table "studies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "blocked",                            :default => false
    t.string   "state",                :limit => 20
    t.boolean  "ethically_approved"
    t.boolean  "enforce_data_release",               :default => true
    t.boolean  "enforce_accessioning",               :default => true
    t.integer  "reference_genome_id",                :default => 1
  end

  add_index "studies", ["ethically_approved"], :name => "index_studies_on_ethically_approved"
  add_index "studies", ["state"], :name => "index_studies_on_state"
  add_index "studies", ["updated_at"], :name => "index_studies_on_updated_at"
  add_index "studies", ["user_id"], :name => "index_projects_on_user_id"

  create_table "study_metadata", :force => true do |t|
    t.integer  "study_id"
    t.string   "old_sac_sponsor"
    t.text     "study_description"
    t.string   "contaminated_human_dna"
    t.string   "study_project_id"
    t.text     "study_abstract"
    t.string   "study_study_title"
    t.string   "study_ebi_accession_number"
    t.string   "study_sra_hold"
    t.string   "contains_human_dna"
    t.string   "study_name_abbreviation"
    t.string   "reference_genome_old"
    t.string   "data_release_strategy"
    t.string   "data_release_standard_agreement"
    t.string   "data_release_timing"
    t.string   "data_release_delay_reason"
    t.string   "data_release_delay_other_comment"
    t.string   "data_release_delay_period"
    t.string   "data_release_delay_approval"
    t.string   "data_release_delay_reason_comment"
    t.string   "data_release_prevention_reason"
    t.string   "data_release_prevention_approval"
    t.string   "data_release_prevention_reason_comment"
    t.integer  "snp_study_id"
    t.integer  "snp_parent_study_id"
    t.boolean  "bam",                                    :default => true
    t.integer  "study_type_id"
    t.integer  "data_release_study_type_id"
    t.integer  "reference_genome_id",                    :default => 1
    t.string   "array_express_accession_number"
    t.text     "dac_policy"
    t.string   "ega_policy_accession_number"
    t.string   "ega_dac_accession_number"
    t.string   "commercially_available",                 :default => "No"
    t.integer  "faculty_sponsor_id"
    t.float    "number_of_gigabases_per_sample"
    t.string   "hmdmc_approval_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remove_x_and_autosomes",                 :default => "No",  :null => false
    t.string   "dac_policy_title"
    t.boolean  "separate_y_chromosome_data",             :default => false, :null => false
    t.string   "data_access_group"
    t.string   "prelim_id"
  end

  add_index "study_metadata", ["faculty_sponsor_id"], :name => "index_study_metadata_on_faculty_sponsor_id"
  add_index "study_metadata", ["prelim_id"], :name => "index_study_metadata_on_prelim_id"
  add_index "study_metadata", ["study_id"], :name => "index_study_metadata_on_study_id"

  create_table "study_relation_types", :force => true do |t|
    t.string "name"
    t.string "reversed_name"
  end

  create_table "study_relations", :force => true do |t|
    t.integer "study_id"
    t.integer "related_study_id"
    t.integer "study_relation_type_id"
  end

  add_index "study_relations", ["related_study_id"], :name => "index_study_relations_on_related_study_id"
  add_index "study_relations", ["study_id"], :name => "index_study_relations_on_study_id"

  create_table "study_reports", :force => true do |t|
    t.integer  "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "report_filename"
    t.string   "content_type",    :default => "text/csv"
  end

  add_index "study_reports", ["created_at"], :name => "index_study_reports_on_created_at"
  add_index "study_reports", ["study_id"], :name => "index_study_reports_on_study_id"
  add_index "study_reports", ["updated_at"], :name => "index_study_reports_on_updated_at"
  add_index "study_reports", ["user_id"], :name => "index_study_reports_on_user_id"

  create_table "study_samples", :force => true do |t|
    t.integer  "study_id",   :null => false
    t.integer  "sample_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "study_samples", ["sample_id", "study_id"], :name => "unique_samples_in_studies_idx", :unique => true
  add_index "study_samples", ["sample_id"], :name => "index_project_samples_on_sample_id"
  add_index "study_samples", ["study_id"], :name => "index_project_samples_on_project_id"

  create_table "study_samples_backup", :id => false, :force => true do |t|
    t.integer "id",        :default => 0, :null => false
    t.integer "study_id"
    t.integer "sample_id"
  end

  create_table "study_types", :force => true do |t|
    t.string   "name"
    t.boolean  "valid_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "valid_for_creation", :default => true, :null => false
  end

  create_table "subclass_attributes", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "attributable_id"
    t.string   "attributable_type", :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subclass_attributes", ["attributable_id", "name"], :name => "index_subclass_attributes_on_attributable_id_and_name"

  create_table "submission_templates", :force => true do |t|
    t.string   "name"
    t.string   "submission_class_name"
    t.text     "submission_parameters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_line_id"
    t.integer  "superceded_by_id",      :default => -1, :null => false
    t.datetime "superceded_at"
  end

  add_index "submission_templates", ["name", "superceded_by_id"], :name => "name_and_superceded_by_unique_idx", :unique => true

  create_table "submission_workflows", :force => true do |t|
    t.string   "key",        :limit => 50
    t.string   "name"
    t.string   "item_label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", :force => true do |t|
    t.integer  "study_id_to_delete"
    t.integer  "workflow_id_to_delete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                      :limit => 20
    t.string   "message"
    t.integer  "user_id"
    t.text     "item_options_to_delete"
    t.text     "request_types"
    t.text     "request_options"
    t.text     "comments_to_delete"
    t.integer  "project_id_to_delete"
    t.string   "sti_type_to_delete"
    t.string   "template_name_to_delete"
    t.integer  "asset_group_id_to_delete"
    t.string   "asset_group_name_to_delete"
    t.string   "name"
    t.integer  "priority",                   :limit => 1,  :default => 0, :null => false
  end

  add_index "submissions", ["state"], :name => "index_submissions_on_state"
  add_index "submissions", ["study_id_to_delete"], :name => "index_submissions_on_project_id"

  create_table "submitted_assets", :force => true do |t|
    t.integer  "order_id"
    t.integer  "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "suppliers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "address"
    t.string   "contact_name"
    t.string   "phone_number"
    t.string   "fax"
    t.string   "url"
    t.string   "abbreviation"
  end

  add_index "suppliers", ["abbreviation"], :name => "index_suppliers_on_abbreviation"
  add_index "suppliers", ["created_at"], :name => "index_suppliers_on_created_at"
  add_index "suppliers", ["name"], :name => "index_suppliers_on_name"
  add_index "suppliers", ["updated_at"], :name => "index_suppliers_on_updated_at"

  create_table "tag2_layout_template_submissions", :force => true do |t|
    t.integer  "submission_id",           :null => false
    t.integer  "tag2_layout_template_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag2_layout_template_submissions", ["submission_id", "tag2_layout_template_id"], :name => "tag2_layouts_used_once_per_submission", :unique => true
  add_index "tag2_layout_template_submissions", ["tag2_layout_template_id"], :name => "fk_tag2_layout_template_submissions_to_tag2_layout_templates"

  create_table "tag2_layout_templates", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "tag_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag2_layouts", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "plate_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id"
  end

  create_table "tag_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",    :default => true
  end

  add_index "tag_groups", ["name"], :name => "tag_groups_unique_name", :unique => true

  create_table "tag_layout_templates", :force => true do |t|
    t.string   "direction_algorithm"
    t.integer  "tag_group_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "walking_algorithm",   :default => "TagLayout::WalkWellsByPools"
  end

  create_table "tag_layouts", :force => true do |t|
    t.string   "direction_algorithm"
    t.integer  "tag_group_id"
    t.integer  "plate_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "substitutions",       :limit => 1525
    t.string   "walking_algorithm",                   :default => "TagLayout::WalkWellsByPools"
    t.integer  "initial_tag",                         :default => 0,                             :null => false
  end

  create_table "tags", :force => true do |t|
    t.string   "oligo"
    t.integer  "map_id"
    t.integer  "tag_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["map_id"], :name => "index_tags_on_map_id"
  add_index "tags", ["tag_group_id"], :name => "index_tags_on_tag_group_id"
  add_index "tags", ["updated_at"], :name => "index_tags_on_updated_at"

  create_table "task_request_types", :force => true do |t|
    t.integer  "task_id"
    t.integer  "request_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order"
  end

  add_index "task_request_types", ["request_type_id"], :name => "index_task_request_types_on_request_type_id"
  add_index "task_request_types", ["task_id"], :name => "index_task_request_types_on_task_id"

  create_table "tasks", :force => true do |t|
    t.string  "name"
    t.integer "pipeline_workflow_id"
    t.integer "sorted"
    t.boolean "batched"
    t.string  "location"
    t.boolean "interactive"
    t.boolean "per_item"
    t.string  "sti_type",             :limit => 50
    t.boolean "lab_activity"
    t.integer "purpose_id"
  end

  add_index "tasks", ["name"], :name => "index_tasks_on_name"
  add_index "tasks", ["pipeline_workflow_id"], :name => "index_tasks_on_pipeline_workflow_id"
  add_index "tasks", ["sorted"], :name => "index_tasks_on_sorted"
  add_index "tasks", ["sti_type"], :name => "index_tasks_on_sti_type"

  create_table "transfer_templates", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "transfer_class_name"
    t.string   "transfers",           :limit => 1024
  end

  create_table "transfers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sti_type"
    t.integer  "source_id"
    t.integer  "destination_id"
    t.string   "destination_type"
    t.text     "transfers"
    t.integer  "bulk_transfer_id"
  end

  add_index "transfers", ["source_id"], :name => "source_id_idx"

  create_table "tube_creation_children", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tube_creation_id", :null => false
    t.integer  "tube_id",          :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "api_key"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "workflow_id"
    t.boolean  "pipeline_administrator"
    t.string   "barcode"
    t.string   "cookie"
    t.datetime "cookie_validated_at"
    t.string   "encrypted_swipecard_code",  :limit => 40
  end

  add_index "users", ["barcode"], :name => "index_users_on_barcode"
  add_index "users", ["encrypted_swipecard_code"], :name => "index_users_on_encrypted_swipecard_code"
  add_index "users", ["login"], :name => "index_users_on_login"
  add_index "users", ["pipeline_administrator"], :name => "index_users_on_pipeline_administrator"

  create_table "uuids", :force => true do |t|
    t.string  "resource_type", :limit => 128, :null => false
    t.integer "resource_id",                  :null => false
    t.string  "external_id",   :limit => 36,  :null => false
  end

  add_index "uuids", ["external_id"], :name => "index_uuids_on_external_id"
  add_index "uuids", ["resource_type", "resource_id"], :name => "index_uuids_on_resource_type_and_resource_id"

  create_table "well_attributes", :force => true do |t|
    t.integer  "well_id"
    t.string   "gel_pass",         :limit => 20
    t.float    "concentration"
    t.float    "current_volume"
    t.float    "buffer_volume"
    t.float    "requested_volume"
    t.float    "picked_volume"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pico_pass",                      :default => "ungraded", :null => false
    t.integer  "sequenom_count"
    t.string   "study_id"
    t.string   "gender_markers"
    t.string   "gender"
    t.float    "measured_volume"
    t.float    "initial_volume"
    t.float    "molarity"
  end

  add_index "well_attributes", ["well_id"], :name => "index_well_attributes_on_well_id"

  create_table "well_links", :force => true do |t|
    t.integer "target_well_id", :null => false
    t.integer "source_well_id", :null => false
    t.string  "type",           :null => false
  end

  add_index "well_links", ["target_well_id"], :name => "target_well_idx"

  create_table "well_to_tube_transfers", :force => true do |t|
    t.integer "transfer_id",    :null => false
    t.integer "destination_id", :null => false
    t.string  "source"
  end

  create_table "workflow_samples", :force => true do |t|
    t.text     "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "control",                     :default => false
    t.integer  "workflow_id"
    t.integer  "submission_id"
    t.string   "state",         :limit => 20
    t.integer  "size",                        :default => 1
    t.integer  "version"
  end

end
