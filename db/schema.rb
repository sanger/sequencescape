# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170321151830) do

  create_table "aliquot_indices", force: :cascade do |t|
    t.integer  "aliquot_id",    limit: 4, null: false
    t.integer  "lane_id",       limit: 4, null: false
    t.integer  "aliquot_index", limit: 4, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "aliquot_indices", ["aliquot_id"], name: "index_aliquot_indices_on_aliquot_id", unique: true, using: :btree
  add_index "aliquot_indices", ["lane_id", "aliquot_index"], name: "index_aliquot_indices_on_lane_id_and_aliquot_index", unique: true, using: :btree

  create_table "aliquots", force: :cascade do |t|
    t.integer  "receptacle_id",    limit: 4,                null: false
    t.integer  "study_id",         limit: 4
    t.integer  "project_id",       limit: 4
    t.integer  "library_id",       limit: 4
    t.integer  "sample_id",        limit: 4,                null: false
    t.integer  "tag_id",           limit: 4
    t.string   "library_type",     limit: 255
    t.integer  "insert_size_from", limit: 4
    t.integer  "insert_size_to",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bait_library_id",  limit: 4
    t.integer  "tag2_id",          limit: 4,   default: -1
  end

  add_index "aliquots", ["library_id"], name: "index_aliquots_on_library_id", using: :btree
  add_index "aliquots", ["receptacle_id", "tag_id", "tag2_id"], name: "aliquot_tags_and_tag2s_are_unique_within_receptacle", unique: true, using: :btree
  add_index "aliquots", ["sample_id"], name: "index_aliquots_on_sample_id", using: :btree
  add_index "aliquots", ["study_id"], name: "index_aliquots_on_study_id", using: :btree
  add_index "aliquots", ["tag_id"], name: "tag_id_idx", using: :btree

  create_table "api_applications", force: :cascade do |t|
    t.string "name",        limit: 255,   null: false
    t.string "key",         limit: 255,   null: false
    t.string "contact",     limit: 255,   null: false
    t.text   "description", limit: 65535
    t.string "privilege",   limit: 255,   null: false
  end

  add_index "api_applications", ["key"], name: "index_api_applications_on_key", using: :btree

  create_table "archived_properties", force: :cascade do |t|
    t.text    "value",           limit: 65535
    t.string  "propertied_type", limit: 255
    t.integer "user_id",         limit: 4
    t.string  "key",             limit: 50
    t.integer "propertied_id",   limit: 4
  end

  create_table "asset_audits", force: :cascade do |t|
    t.string   "message",      limit: 255
    t.string   "key",          limit: 255
    t.string   "created_by",   limit: 255
    t.integer  "asset_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "witnessed_by", limit: 255
  end

  add_index "asset_audits", ["asset_id"], name: "index_asset_audits_on_asset_id", using: :btree

  create_table "asset_barcodes", force: :cascade do |t|
  end

  create_table "asset_creation_parents", force: :cascade do |t|
    t.integer  "asset_creation_id", limit: 4
    t.integer  "parent_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "asset_creations", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.integer  "parent_id",        limit: 4
    t.integer  "child_purpose_id", limit: 4
    t.integer  "child_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",             limit: 255, null: false
  end

  create_table "asset_group_assets", force: :cascade do |t|
    t.integer  "asset_id",       limit: 4
    t.integer  "asset_group_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "asset_group_assets", ["asset_group_id"], name: "index_asset_group_assets_on_asset_group_id", using: :btree
  add_index "asset_group_assets", ["asset_id"], name: "index_asset_group_assets_on_asset_id", using: :btree

  create_table "asset_groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "user_id",    limit: 4
    t.integer  "study_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "asset_links", force: :cascade do |t|
    t.integer  "ancestor_id",   limit: 4
    t.integer  "descendant_id", limit: 4
    t.boolean  "direct"
    t.integer  "count",         limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "asset_links", ["ancestor_id", "direct"], name: "index_asset_links_on_ancestor_id_and_direct", using: :btree
  add_index "asset_links", ["descendant_id", "direct"], name: "index_asset_links_on_descendant_id_and_direct", using: :btree

  create_table "asset_shapes", force: :cascade do |t|
    t.string   "name",                 limit: 255, null: false
    t.integer  "horizontal_ratio",     limit: 4,   null: false
    t.integer  "vertical_ratio",       limit: 4,   null: false
    t.string   "description_strategy", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", force: :cascade do |t|
    t.string   "name",                    limit: 255
    t.string   "value",                   limit: 255
    t.text     "descriptors",             limit: 65535
    t.text     "descriptor_fields",       limit: 65535
    t.string   "sti_type",                limit: 50
    t.string   "barcode",                 limit: 255
    t.string   "qc_state",                limit: 20
    t.boolean  "resource"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "map_id",                  limit: 4
    t.integer  "size",                    limit: 4
    t.boolean  "closed",                                                         default: false
    t.string   "public_name",             limit: 255
    t.boolean  "archive"
    t.boolean  "external_release"
    t.string   "two_dimensional_barcode", limit: 255
    t.integer  "plate_purpose_id",        limit: 4
    t.decimal  "volume",                                precision: 10, scale: 2
    t.integer  "barcode_prefix_id",       limit: 4
    t.decimal  "concentration",                         precision: 18, scale: 8
    t.integer  "legacy_sample_id",        limit: 4
    t.integer  "legacy_tag_id",           limit: 4
  end

  add_index "assets", ["barcode"], name: "index_assets_on_barcode", using: :btree
  add_index "assets", ["barcode_prefix_id"], name: "index_assets_on_barcode_prefix_id", using: :btree
  add_index "assets", ["legacy_sample_id"], name: "index_assets_on_sample_id", using: :btree
  add_index "assets", ["map_id"], name: "index_assets_on_map_id", using: :btree
  add_index "assets", ["sti_type", "plate_purpose_id"], name: "index_assets_on_plate_purpose_id_sti_type", using: :btree
  add_index "assets", ["sti_type", "updated_at"], name: "index_assets_on_sti_type_and_updated_at", using: :btree
  add_index "assets", ["sti_type"], name: "index_assets_on_sti_type", using: :btree
  add_index "assets", ["updated_at"], name: "index_assets_on_updated_at", using: :btree

  create_table "attachments", force: :cascade do |t|
    t.integer "pipeline_workflow_id", limit: 4
    t.integer "attachable_id",        limit: 4
    t.string  "attachable_type",      limit: 50
    t.integer "position",             limit: 4
  end

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id",   limit: 4
    t.string   "auditable_type", limit: 255
    t.integer  "user_id",        limit: 4
    t.string   "user_type",      limit: 255
    t.string   "username",       limit: 255
    t.string   "action",         limit: 255
    t.text     "changes",        limit: 65535
    t.integer  "version",        limit: 4,     default: 0
    t.datetime "created_at"
  end

  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "bait_libraries", force: :cascade do |t|
    t.integer  "bait_library_supplier_id", limit: 4
    t.string   "name",                     limit: 255,                null: false
    t.string   "supplier_identifier",      limit: 255
    t.string   "target_species",           limit: 255,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bait_library_type_id",     limit: 4,                  null: false
    t.boolean  "visible",                              default: true, null: false
  end

  add_index "bait_libraries", ["bait_library_supplier_id", "name"], name: "bait_library_names_are_unique_within_a_supplier", unique: true, using: :btree

  create_table "bait_library_layouts", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "plate_id",   limit: 4,    null: false
    t.string   "layout",     limit: 1024
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bait_library_layouts", ["plate_id"], name: "bait_libraries_are_laid_out_on_a_plate_once", unique: true, using: :btree

  create_table "bait_library_suppliers", force: :cascade do |t|
    t.string   "name",       limit: 255,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",                default: true, null: false
  end

  add_index "bait_library_suppliers", ["name"], name: "index_bait_library_suppliers_on_name", unique: true, using: :btree

  create_table "bait_library_types", force: :cascade do |t|
    t.string   "name",       limit: 255,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",                default: true, null: false
  end

  add_index "bait_library_types", ["name"], name: "index_bait_library_types_on_name", unique: true, using: :btree

  create_table "barcode_prefixes", force: :cascade do |t|
    t.string "prefix", limit: 3
  end

  add_index "barcode_prefixes", ["prefix"], name: "index_barcode_prefixes_on_prefix", using: :btree

  create_table "barcode_printer_types", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "printer_type_id",     limit: 4
    t.string   "type",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label_template_name", limit: 255
  end

  add_index "barcode_printer_types", ["name"], name: "index_barcode_printer_types_on_name", using: :btree
  add_index "barcode_printer_types", ["printer_type_id"], name: "index_barcode_printer_types_on_printer_type_id", using: :btree
  add_index "barcode_printer_types", ["type"], name: "index_barcode_printer_types_on_type", using: :btree

  create_table "barcode_printers", force: :cascade do |t|
    t.string   "name",                    limit: 255
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "barcode_printer_type_id", limit: 4
  end

  create_table "batch_requests", force: :cascade do |t|
    t.integer  "batch_id",   limit: 4, null: false
    t.integer  "request_id", limit: 4, null: false
    t.integer  "position",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "batch_requests", ["batch_id"], name: "index_batch_requests_on_batch_id", using: :btree
  add_index "batch_requests", ["request_id"], name: "index_batch_requests_on_request_id", using: :btree
  add_index "batch_requests", ["request_id"], name: "request_id", unique: true, using: :btree
  add_index "batch_requests", ["updated_at"], name: "index_batch_requests_on_updated_at", using: :btree

  create_table "batches", force: :cascade do |t|
    t.integer  "item_limit",       limit: 4
    t.datetime "created_at"
    t.integer  "user_id",          limit: 4
    t.datetime "updated_at"
    t.integer  "pipeline_id",      limit: 4
    t.string   "state",            limit: 20
    t.integer  "assignee_id",      limit: 4
    t.integer  "qc_pipeline_id",   limit: 4
    t.string   "production_state", limit: 255
    t.string   "qc_state",         limit: 25
    t.string   "barcode",          limit: 255
  end

  add_index "batches", ["pipeline_id", "state", "created_at"], name: "index_batches_on_pipeline_id_and_state_and_created_at", using: :btree
  add_index "batches", ["updated_at"], name: "index_batches_on_updated_at", using: :btree

  create_table "billing_events", force: :cascade do |t|
    t.string   "kind",        limit: 255, default: "charge",      null: false
    t.datetime "entry_date",                                      null: false
    t.string   "created_by",  limit: 255,                         null: false
    t.integer  "project_id",  limit: 4,                           null: false
    t.string   "reference",   limit: 255,                         null: false
    t.string   "description", limit: 255, default: "Unspecified"
    t.float    "quantity",    limit: 24,  default: 1.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_id",  limit: 4,                           null: false
  end

  add_index "billing_events", ["kind"], name: "index_billing_events_on_kind", using: :btree
  add_index "billing_events", ["reference"], name: "index_billing_events_on_reference", using: :btree

  create_table "broadcast_events", force: :cascade do |t|
    t.string   "sti_type",   limit: 255
    t.string   "seed_type",  limit: 255
    t.integer  "seed_id",    limit: 4
    t.integer  "user_id",    limit: 4
    t.text     "properties", limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "budget_divisions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bulk_transfers", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    limit: 4
  end

  create_table "comments", force: :cascade do |t|
    t.string   "title",            limit: 255
    t.string   "commentable_type", limit: 50
    t.integer  "user_id",          limit: 4
    t.text     "description",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "commentable_id",   limit: 4,     null: false
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree

  create_table "container_associations", force: :cascade do |t|
    t.integer "container_id", limit: 4, null: false
    t.integer "content_id",   limit: 4, null: false
  end

  add_index "container_associations", ["container_id"], name: "index_container_associations_on_container_id", using: :btree
  add_index "container_associations", ["content_id"], name: "container_association_content_is_unique", unique: true, using: :btree

  create_table "controls", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "item_id",     limit: 4
    t.integer  "pipeline_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_metadata", force: :cascade do |t|
    t.string   "key",                            limit: 255
    t.string   "value",                          limit: 255
    t.integer  "custom_metadatum_collection_id", limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "custom_metadata", ["custom_metadatum_collection_id"], name: "index_custom_metadata_on_custom_metadatum_collection_id", using: :btree

  create_table "custom_metadatum_collections", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "asset_id",   limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "custom_metadatum_collections", ["asset_id"], name: "index_custom_metadatum_collections_on_asset_id", using: :btree
  add_index "custom_metadatum_collections", ["user_id"], name: "index_custom_metadatum_collections_on_user_id", using: :btree

  create_table "custom_texts", force: :cascade do |t|
    t.string   "identifier",   limit: 255
    t.integer  "differential", limit: 4
    t.string   "content_type", limit: 255
    t.text     "content",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_release_study_types", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "for_array_express",             default: false
    t.boolean  "is_default",                    default: false
    t.boolean  "is_assay_type",                 default: false
  end

  create_table "db_files", force: :cascade do |t|
    t.binary  "data",                limit: 4294967295
    t.integer "owner_id",            limit: 4
    t.string  "owner_type",          limit: 25,         default: "Document", null: false
    t.string  "owner_type_extended", limit: 255
  end

  add_index "db_files", ["owner_type", "owner_id"], name: "index_db_files_on_owner_type_and_owner_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue",      limit: 255
  end

  create_table "depricated_attempts", force: :cascade do |t|
    t.string   "state",       limit: 20, default: "pending"
    t.integer  "request_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "workflow_id", limit: 4
  end

  add_index "depricated_attempts", ["request_id"], name: "index_attempts_on_request_id", using: :btree

  create_table "descriptors", force: :cascade do |t|
    t.string  "name",      limit: 255
    t.string  "value",     limit: 255
    t.text    "selection", limit: 65535
    t.integer "task_id",   limit: 4
    t.string  "kind",      limit: 255
    t.boolean "required"
    t.integer "sorter",    limit: 4
    t.integer "family_id", limit: 4
    t.string  "key",       limit: 50
  end

  add_index "descriptors", ["task_id"], name: "index_descriptors_on_task_id", using: :btree

  create_table "documents", force: :cascade do |t|
    t.integer "documentable_id",       limit: 4
    t.integer "size",                  limit: 4
    t.string  "content_type",          limit: 255
    t.string  "filename",              limit: 255
    t.integer "height",                limit: 4
    t.integer "width",                 limit: 4
    t.integer "parent_id",             limit: 4
    t.string  "thumbnail",             limit: 255
    t.integer "db_file_id",            limit: 4
    t.string  "documentable_type",     limit: 50,  null: false
    t.string  "documentable_extended", limit: 50
  end

  add_index "documents", ["documentable_id", "documentable_type"], name: "index_documents_on_documentable_id_and_documentable_type", using: :btree
  add_index "documents", ["documentable_type", "documentable_id"], name: "index_documents_on_documentable_type_and_documentable_id", using: :btree

  create_table "documents_shadow", force: :cascade do |t|
    t.integer "documentable_id",   limit: 4
    t.integer "size",              limit: 4
    t.string  "content_type",      limit: 255
    t.string  "filename",          limit: 255
    t.integer "height",            limit: 4
    t.integer "width",             limit: 4
    t.integer "parent_id",         limit: 4
    t.string  "thumbnail",         limit: 255
    t.integer "db_file_id",        limit: 4
    t.string  "documentable_type", limit: 50
  end

  add_index "documents_shadow", ["documentable_id", "documentable_type"], name: "index_documents_on_documentable_id_and_documentable_type", using: :btree

  create_table "equipment", force: :cascade do |t|
    t.string "name",           limit: 255
    t.string "equipment_type", limit: 255
    t.string "prefix",         limit: 2,   null: false
    t.string "ean13_barcode",  limit: 13
  end

  create_table "events", force: :cascade do |t|
    t.integer  "eventful_id",    limit: 4
    t.string   "eventful_type",  limit: 50
    t.string   "message",        limit: 255
    t.string   "family",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "identifier",     limit: 255
    t.string   "location",       limit: 255
    t.boolean  "actioned"
    t.text     "content",        limit: 65535
    t.string   "created_by",     limit: 255
    t.string   "of_interest_to", limit: 255
    t.string   "descriptor_key", limit: 50
    t.string   "type",           limit: 255,   default: "Event"
  end

  add_index "events", ["eventful_id"], name: "index_events_on_eventful_id", using: :btree
  add_index "events", ["eventful_type"], name: "index_events_on_eventful_type", using: :btree
  add_index "events", ["family"], name: "index_events_on_family", using: :btree

  create_table "extended_validators", force: :cascade do |t|
    t.string   "behaviour",  limit: 255,   null: false
    t.text     "options",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_properties", force: :cascade do |t|
    t.integer  "propertied_id",   limit: 4
    t.string   "propertied_type", limit: 50
    t.string   "key",             limit: 50
    t.string   "value",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_properties", ["propertied_id", "propertied_type", "key"], name: "ep_pi_pt_key", using: :btree
  add_index "external_properties", ["propertied_id", "propertied_type"], name: "ep_pi_pt", using: :btree
  add_index "external_properties", ["propertied_type", "key"], name: "index_external_properties_on_propertied_type_and_key", using: :btree
  add_index "external_properties", ["value"], name: "index_external_properties_on_value", using: :btree

  create_table "extraction_attributes", force: :cascade do |t|
    t.integer  "target_id",         limit: 4
    t.string   "created_by",        limit: 255
    t.text     "attributes_update", limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "faculty_sponsors", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "failures", force: :cascade do |t|
    t.integer  "failable_id",   limit: 4
    t.string   "failable_type", limit: 50
    t.text     "reason",        limit: 65535
    t.boolean  "notify_remote"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment",       limit: 65535
  end

  add_index "failures", ["failable_id"], name: "index_failures_on_failable_id", using: :btree

  create_table "families", force: :cascade do |t|
    t.string  "name",                 limit: 255
    t.text    "description",          limit: 65535
    t.string  "relates_to",           limit: 255
    t.integer "task_id",              limit: 4
    t.integer "pipeline_workflow_id", limit: 4
  end

  create_table "identifiers", force: :cascade do |t|
    t.integer "identifiable_id",   limit: 4
    t.string  "identifiable_type", limit: 50
    t.string  "resource_name",     limit: 255
    t.integer "external_id",       limit: 4
    t.string  "external_type",     limit: 50
    t.boolean "do_not_sync",                   default: false
  end

  add_index "identifiers", ["external_id", "identifiable_id"], name: "index_identifiers_on_external_id_and_identifiable_id", using: :btree
  add_index "identifiers", ["external_type"], name: "index_identifiers_on_external_type", using: :btree
  add_index "identifiers", ["identifiable_id", "identifiable_type"], name: "index_identifiers_on_identifiable_id_and_identifiable_type", using: :btree
  add_index "identifiers", ["resource_name"], name: "index_identifiers_on_resource_name", using: :btree

  create_table "implements", force: :cascade do |t|
    t.string "name",           limit: 255
    t.string "barcode",        limit: 255
    t.string "equipment_type", limit: 255
  end

  add_index "implements", ["barcode"], name: "index_implements_on_barcode", using: :btree

  create_table "items", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",               limit: 255
    t.integer  "study_id",           limit: 4
    t.integer  "user_id",            limit: 4
    t.integer  "count",              limit: 4
    t.integer  "workflow_sample_id", limit: 4
    t.boolean  "closed",                         default: false
    t.integer  "pool_id",            limit: 4
    t.integer  "workflow_id",        limit: 4
    t.integer  "version",            limit: 4
    t.integer  "submission_id",      limit: 4
  end

  add_index "items", ["name"], name: "index_items_on_name", using: :btree
  add_index "items", ["study_id"], name: "index_items_on_study_id", using: :btree
  add_index "items", ["submission_id"], name: "index_items_on_submission_id", using: :btree
  add_index "items", ["version"], name: "index_items_on_version", using: :btree
  add_index "items", ["workflow_id"], name: "index_items_on_workflow_id", using: :btree
  add_index "items", ["workflow_sample_id"], name: "index_items_on_sample_id", using: :btree

  create_table "lab_events", force: :cascade do |t|
    t.text     "description",       limit: 65535
    t.text     "descriptors",       limit: 65535
    t.text     "descriptor_fields", limit: 65535
    t.integer  "eventful_id",       limit: 4
    t.string   "eventful_type",     limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename",          limit: 255
    t.binary   "data",              limit: 65535
    t.text     "message",           limit: 65535
    t.integer  "user_id",           limit: 4
    t.integer  "batch_id",          limit: 4
  end

  add_index "lab_events", ["batch_id"], name: "index_lab_events_on_batch_id", using: :btree
  add_index "lab_events", ["created_at"], name: "index_lab_events_on_created_at", using: :btree
  add_index "lab_events", ["description", "eventful_type"], name: "index_lab_events_find_flowcell", length: {"description"=>20, "eventful_type"=>nil}, using: :btree
  add_index "lab_events", ["eventful_id"], name: "index_lab_events_on_eventful_id", using: :btree
  add_index "lab_events", ["eventful_type"], name: "index_lab_events_on_eventful_type", using: :btree

  create_table "lab_interface_workflows", force: :cascade do |t|
    t.string  "name",        limit: 255
    t.integer "item_limit",  limit: 4
    t.text    "locale",      limit: 65535
    t.integer "pipeline_id", limit: 4
  end

  add_index "lab_interface_workflows", ["pipeline_id"], name: "index_lab_interface_workflows_on_pipeline_id", using: :btree

  create_table "lane_metadata", force: :cascade do |t|
    t.integer  "lane_id",        limit: 4
    t.string   "release_reason", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "library_types", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "library_types_request_types", force: :cascade do |t|
    t.integer  "request_type_id", limit: 4,                 null: false
    t.integer  "library_type_id", limit: 4,                 null: false
    t.boolean  "is_default",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "library_types_request_types", ["library_type_id"], name: "fk_library_types_request_types_to_library_types", using: :btree
  add_index "library_types_request_types", ["request_type_id"], name: "fk_library_types_request_types_to_request_types", using: :btree

  create_table "location_associations", force: :cascade do |t|
    t.integer "locatable_id", limit: 4, null: false
    t.integer "location_id",  limit: 4, null: false
  end

  add_index "location_associations", ["locatable_id"], name: "single_location_per_locatable_idx", unique: true, using: :btree
  add_index "location_associations", ["location_id"], name: "index_location_associations_on_location_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "lot_types", force: :cascade do |t|
    t.string   "name",              limit: 255, null: false
    t.string   "template_class",    limit: 255, null: false
    t.integer  "target_purpose_id", limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lot_types", ["target_purpose_id"], name: "fk_lot_types_to_plate_purposes", using: :btree

  create_table "lots", force: :cascade do |t|
    t.string   "lot_number",    limit: 255, null: false
    t.integer  "lot_type_id",   limit: 4,   null: false
    t.integer  "template_id",   limit: 4,   null: false
    t.string   "template_type", limit: 255, null: false
    t.integer  "user_id",       limit: 4,   null: false
    t.date     "received_at",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lots", ["lot_number", "lot_type_id"], name: "index_lot_number_lot_type_id", unique: true, using: :btree
  add_index "lots", ["lot_type_id"], name: "fk_lots_to_lot_types", using: :btree

  create_table "maps", force: :cascade do |t|
    t.string  "description",    limit: 4
    t.integer "asset_size",     limit: 4
    t.integer "location_id",    limit: 4
    t.integer "row_order",      limit: 4
    t.integer "column_order",   limit: 4
    t.integer "asset_shape_id", limit: 4, default: 1, null: false
  end

  add_index "maps", ["description", "asset_size"], name: "index_maps_on_description_and_asset_size", using: :btree
  add_index "maps", ["description"], name: "index_maps_on_description", using: :btree

  create_table "messenger_creators", force: :cascade do |t|
    t.string   "template",   limit: 255, null: false
    t.string   "root",       limit: 255, null: false
    t.integer  "purpose_id", limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messenger_creators", ["purpose_id"], name: "fk_messenger_creators_to_plate_purposes", using: :btree

  create_table "messengers", force: :cascade do |t|
    t.integer  "target_id",   limit: 4
    t.string   "target_type", limit: 255
    t.string   "root",        limit: 255, null: false
    t.string   "template",    limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_roles", force: :cascade do |t|
    t.string   "role",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "study_id",          limit: 4
    t.integer  "workflow_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state_to_delete",   limit: 20
    t.string   "message_to_delete", limit: 255
    t.integer  "user_id",           limit: 4
    t.text     "item_options",      limit: 65535
    t.text     "request_types",     limit: 65535
    t.text     "request_options",   limit: 65535
    t.text     "comments",          limit: 65535
    t.integer  "project_id",        limit: 4
    t.string   "sti_type",          limit: 255
    t.string   "template_name",     limit: 255
    t.integer  "asset_group_id",    limit: 4
    t.string   "asset_group_name",  limit: 255
    t.integer  "submission_id",     limit: 4
    t.integer  "pre_cap_group",     limit: 4
    t.integer  "order_role_id",     limit: 4
    t.integer  "product_id",        limit: 4
  end

  add_index "orders", ["state_to_delete"], name: "index_submissions_on_state", using: :btree
  add_index "orders", ["study_id"], name: "index_submissions_on_project_id", using: :btree

  create_table "pac_bio_library_tube_metadata", force: :cascade do |t|
    t.integer  "smrt_cells_available",    limit: 4
    t.string   "prep_kit_barcode",        limit: 255
    t.string   "binding_kit_barcode",     limit: 255
    t.string   "movie_length",            limit: 255
    t.integer  "pac_bio_library_tube_id", limit: 4
    t.string   "protocol",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pac_bio_library_tube_metadata", ["pac_bio_library_tube_id"], name: "index_pac_bio_library_tube_metadata_on_pac_bio_library_tube_id", using: :btree

  create_table "permissions", force: :cascade do |t|
    t.string   "role_name",        limit: 255
    t.string   "name",             limit: 255
    t.string   "permissable_type", limit: 50
    t.integer  "permissable_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["permissable_id"], name: "index_permissions_on_permissable_id", using: :btree

  create_table "pipeline_request_information_types", force: :cascade do |t|
    t.integer  "pipeline_id",                 limit: 4
    t.integer  "request_information_type_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pipelines", force: :cascade do |t|
    t.string   "name",                          limit: 255
    t.boolean  "automated"
    t.boolean  "active",                                    default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "next_pipeline_id",              limit: 4
    t.integer  "previous_pipeline_id",          limit: 4
    t.integer  "location_id",                   limit: 4
    t.boolean  "group_by_parent"
    t.string   "asset_type",                    limit: 50
    t.boolean  "group_by_submission_to_delete"
    t.boolean  "multiplexed"
    t.string   "sti_type",                      limit: 50
    t.integer  "sorter",                        limit: 4
    t.boolean  "paginate",                                  default: false
    t.integer  "max_size",                      limit: 4
    t.boolean  "summary",                                   default: true
    t.boolean  "group_by_study_to_delete",                  default: true
    t.integer  "max_number_of_groups",          limit: 4
    t.boolean  "externally_managed",                        default: false
    t.string   "group_name",                    limit: 255
    t.integer  "control_request_type_id",       limit: 4,                   null: false
    t.integer  "min_size",                      limit: 4
  end

  add_index "pipelines", ["sorter"], name: "index_pipelines_on_sorter", using: :btree

  create_table "pipelines_request_types", force: :cascade do |t|
    t.integer "pipeline_id",     limit: 4, null: false
    t.integer "request_type_id", limit: 4, null: false
  end

  add_index "pipelines_request_types", ["pipeline_id"], name: "fk_pipelines_request_types_to_pipelines", using: :btree
  add_index "pipelines_request_types", ["request_type_id"], name: "fk_pipelines_request_types_to_request_types", using: :btree

  create_table "plate_conversions", force: :cascade do |t|
    t.integer  "target_id",  limit: 4, null: false
    t.integer  "purpose_id", limit: 4, null: false
    t.integer  "user_id",    limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",  limit: 4
  end

  create_table "plate_creator_parent_purposes", force: :cascade do |t|
    t.integer  "plate_creator_id", limit: 4, null: false
    t.integer  "plate_purpose_id", limit: 4, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "plate_creator_purposes", force: :cascade do |t|
    t.integer  "plate_creator_id", limit: 4, null: false
    t.integer  "plate_purpose_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "plate_creators", force: :cascade do |t|
    t.string   "name",          limit: 255,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "valid_options", limit: 65535
  end

  add_index "plate_creators", ["name"], name: "index_plate_creators_on_name", unique: true, using: :btree

  create_table "plate_metadata", force: :cascade do |t|
    t.integer  "plate_id",         limit: 4
    t.string   "infinium_barcode", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fluidigm_barcode", limit: 10
    t.decimal  "dilution_factor",              precision: 5, scale: 2, default: 1.0
  end

  add_index "plate_metadata", ["fluidigm_barcode"], name: "index_on_fluidigm_barcode", unique: true, using: :btree
  add_index "plate_metadata", ["plate_id"], name: "index_plate_metadata_on_plate_id", using: :btree

  create_table "plate_owners", force: :cascade do |t|
    t.integer  "user_id",        limit: 4,   null: false
    t.integer  "plate_id",       limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "eventable_id",   limit: 4,   null: false
    t.string   "eventable_type", limit: 255, null: false
  end

  create_table "plate_purpose_relationships", force: :cascade do |t|
    t.integer "parent_id",                limit: 4
    t.integer "child_id",                 limit: 4
    t.integer "transfer_request_type_id", limit: 4, null: false
  end

  create_table "plate_purposes", force: :cascade do |t|
    t.string   "name",                    limit: 255,                           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                    limit: 255
    t.string   "target_type",             limit: 30
    t.boolean  "stock_plate",                         default: false,           null: false
    t.string   "default_state",           limit: 255, default: "pending"
    t.integer  "barcode_printer_type_id", limit: 4,   default: 2
    t.boolean  "cherrypickable_target",               default: true,            null: false
    t.boolean  "cherrypickable_source",               default: false,           null: false
    t.string   "cherrypick_direction",    limit: 255, default: "column",        null: false
    t.integer  "default_location_id",     limit: 4
    t.string   "cherrypick_filters",      limit: 255
    t.integer  "size",                    limit: 4,   default: 96
    t.integer  "asset_shape_id",          limit: 4,   default: 1,               null: false
    t.string   "barcode_for_tecan",       limit: 255, default: "ean13_barcode", null: false
    t.integer  "source_purpose_id",       limit: 4
    t.integer  "lifespan",                limit: 4
  end

  add_index "plate_purposes", ["target_type"], name: "index_plate_purposes_on_target_type", using: :btree
  add_index "plate_purposes", ["type"], name: "index_plate_purposes_on_type", using: :btree
  add_index "plate_purposes", ["updated_at"], name: "index_plate_purposes_on_updated_at", using: :btree

  create_table "plate_volumes", force: :cascade do |t|
    t.string   "barcode",            limit: 255
    t.string   "uploaded_file_name", limit: 255
    t.string   "state",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plate_volumes", ["uploaded_file_name"], name: "index_plate_volumes_on_uploaded_file_name", using: :btree

  create_table "pooling_methods", force: :cascade do |t|
    t.string "pooling_behaviour", limit: 50,    null: false
    t.text   "pooling_options",   limit: 65535
  end

  create_table "pre_capture_pool_pooled_requests", force: :cascade do |t|
    t.integer "pre_capture_pool_id", limit: 4, null: false
    t.integer "request_id",          limit: 4, null: false
  end

  add_index "pre_capture_pool_pooled_requests", ["request_id"], name: "request_id_should_be_unique", unique: true, using: :btree

  create_table "pre_capture_pools", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_catalogues", force: :cascade do |t|
    t.string   "name",                limit: 255,                           null: false
    t.string   "selection_behaviour", limit: 255, default: "SingleProduct", null: false
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
  end

  create_table "product_criteria", force: :cascade do |t|
    t.integer  "product_id",    limit: 4,                       null: false
    t.string   "stage",         limit: 255,                     null: false
    t.string   "behaviour",     limit: 255,   default: "Basic", null: false
    t.text     "configuration", limit: 65535
    t.datetime "deprecated_at"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "version",       limit: 4
  end

  add_index "product_criteria", ["product_id", "stage", "version"], name: "index_product_criteria_on_product_id_and_stage_and_version", unique: true, using: :btree

  create_table "product_lines", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "product_product_catalogues", force: :cascade do |t|
    t.integer  "product_id",           limit: 4,   null: false
    t.integer  "product_catalogue_id", limit: 4,   null: false
    t.string   "selection_criterion",  limit: 255
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "product_product_catalogues", ["product_catalogue_id"], name: "fk_product_product_catalogues_to_product_catalogues", using: :btree
  add_index "product_product_catalogues", ["product_id"], name: "fk_product_product_catalogues_to_products", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "name",          limit: 255, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.datetime "deprecated_at"
  end

  create_table "programs", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "project_managers", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_metadata", force: :cascade do |t|
    t.integer  "project_id",                    limit: 4
    t.string   "project_cost_code",             limit: 255
    t.string   "funding_comments",              limit: 255
    t.string   "collaborators",                 limit: 255
    t.string   "external_funding_source",       limit: 255
    t.string   "sequencing_budget_cost_centre", limit: 255
    t.string   "project_funding_model",         limit: 255
    t.string   "gt_committee_tracking_id",      limit: 255
    t.integer  "project_manager_id",            limit: 4,   default: 1
    t.integer  "budget_division_id",            limit: 4,   default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_metadata", ["project_id"], name: "index_project_metadata_on_project_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.boolean  "enforce_quotas",             default: true
    t.boolean  "approved",                   default: false
    t.string   "state",          limit: 20,  default: "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["approved"], name: "index_projects_on_approved", using: :btree
  add_index "projects", ["enforce_quotas"], name: "index_projects_on_enforce_quotas", using: :btree
  add_index "projects", ["state"], name: "index_projects_on_state", using: :btree
  add_index "projects", ["updated_at"], name: "index_projects_on_updated_at", using: :btree

  create_table "qc_decision_qcables", force: :cascade do |t|
    t.integer  "qc_decision_id", limit: 4,   null: false
    t.integer  "qcable_id",      limit: 4,   null: false
    t.string   "decision",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_decisions", force: :cascade do |t|
    t.integer  "lot_id",     limit: 4, null: false
    t.integer  "user_id",    limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_files", force: :cascade do |t|
    t.integer  "asset_id",     limit: 4
    t.string   "asset_type",   limit: 255
    t.integer  "size",         limit: 4
    t.string   "content_type", limit: 255
    t.string   "filename",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_metric_requests", force: :cascade do |t|
    t.integer  "qc_metric_id", limit: 4, null: false
    t.integer  "request_id",   limit: 4, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "qc_metric_requests", ["qc_metric_id"], name: "fk_qc_metric_requests_to_qc_metrics", using: :btree
  add_index "qc_metric_requests", ["request_id"], name: "fk_qc_metric_requests_to_requests", using: :btree

  create_table "qc_metrics", force: :cascade do |t|
    t.integer  "qc_report_id", limit: 4,     null: false
    t.integer  "asset_id",     limit: 4,     null: false
    t.text     "metrics",      limit: 65535
    t.string   "qc_decision",  limit: 255,   null: false
    t.boolean  "proceed"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "qc_metrics", ["asset_id"], name: "fk_qc_metrics_to_assets", using: :btree
  add_index "qc_metrics", ["qc_report_id"], name: "fk_qc_metrics_to_qc_reports", using: :btree

  create_table "qc_reports", force: :cascade do |t|
    t.string   "report_identifier",   limit: 255, null: false
    t.integer  "study_id",            limit: 4,   null: false
    t.integer  "product_criteria_id", limit: 4,   null: false
    t.boolean  "exclude_existing",                null: false
    t.string   "state",               limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "qc_reports", ["product_criteria_id"], name: "fk_qc_reports_to_product_criteria", using: :btree
  add_index "qc_reports", ["report_identifier"], name: "index_qc_reports_on_report_identifier", unique: true, using: :btree
  add_index "qc_reports", ["study_id"], name: "fk_qc_reports_to_studies", using: :btree

  create_table "qcable_creators", force: :cascade do |t|
    t.integer  "lot_id",     limit: 4, null: false
    t.integer  "user_id",    limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qcables", force: :cascade do |t|
    t.integer  "lot_id",            limit: 4,   null: false
    t.integer  "asset_id",          limit: 4,   null: false
    t.string   "state",             limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "qcable_creator_id", limit: 4,   null: false
  end

  add_index "qcables", ["asset_id"], name: "index_asset_id", using: :btree
  add_index "qcables", ["lot_id"], name: "index_lot_id", using: :btree

  create_table "quotas_bkp", force: :cascade do |t|
    t.integer  "limit",            limit: 4, default: 0
    t.integer  "project_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_type_id",  limit: 4
    t.integer  "preordered_count", limit: 4, default: 0
  end

  add_index "quotas_bkp", ["request_type_id", "project_id"], name: "index_quotas_on_request_type_id_and_project_id", using: :btree
  add_index "quotas_bkp", ["updated_at"], name: "index_quotas_on_updated_at", using: :btree

  create_table "reference_genomes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_events", force: :cascade do |t|
    t.integer  "request_id",   limit: 4,   null: false
    t.string   "event_name",   limit: 255, null: false
    t.string   "from_state",   limit: 255
    t.string   "to_state",     limit: 255
    t.datetime "current_from",             null: false
    t.datetime "current_to"
  end

  add_index "request_events", ["request_id", "current_to"], name: "index_request_events_on_request_id_and_current_to", using: :btree

  create_table "request_information_types", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "key",           limit: 50
    t.string   "label",         limit: 255
    t.integer  "width",         limit: 4
    t.string   "data_type",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hide_in_inbox"
  end

  create_table "request_informations", force: :cascade do |t|
    t.integer  "request_id",                  limit: 4
    t.integer  "request_information_type_id", limit: 4
    t.string   "value",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "request_informations", ["request_id"], name: "index_request_informations_on_request_id", using: :btree

  create_table "request_metadata", force: :cascade do |t|
    t.integer  "request_id",                      limit: 4
    t.string   "name",                            limit: 255
    t.string   "tag",                             limit: 255
    t.string   "library_type",                    limit: 255
    t.string   "fragment_size_required_to",       limit: 255
    t.string   "fragment_size_required_from",     limit: 255
    t.integer  "read_length",                     limit: 4
    t.integer  "batch_id",                        limit: 4
    t.integer  "pipeline_id",                     limit: 4
    t.string   "pass",                            limit: 255
    t.string   "failure",                         limit: 255
    t.string   "library_creation_complete",       limit: 255
    t.string   "sequencing_type",                 limit: 255
    t.integer  "insert_size",                     limit: 4
    t.integer  "bait_library_id",                 limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pre_capture_plex_level",          limit: 4
    t.float    "gigabases_expected",              limit: 24
    t.integer  "target_purpose_id",               limit: 4
    t.boolean  "customer_accepts_responsibility"
  end

  add_index "request_metadata", ["request_id"], name: "index_request_metadata_on_request_id", using: :btree

  create_table "request_purposes", force: :cascade do |t|
    t.string   "key",        limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "request_quotas_bkp", force: :cascade do |t|
    t.integer "request_id", limit: 4, null: false
    t.integer "quota_id",   limit: 4, null: false
  end

  add_index "request_quotas_bkp", ["quota_id", "request_id"], name: "index_request_quotas_on_quota_id_and_request_id", using: :btree
  add_index "request_quotas_bkp", ["request_id"], name: "fk_request_quotas_to_requests", using: :btree

  create_table "request_type_plate_purposes", force: :cascade do |t|
    t.integer "request_type_id",  limit: 4, null: false
    t.integer "plate_purpose_id", limit: 4, null: false
  end

  add_index "request_type_plate_purposes", ["request_type_id", "plate_purpose_id"], name: "plate_purposes_are_unique_within_request_type", unique: true, using: :btree

  create_table "request_type_validators", force: :cascade do |t|
    t.integer  "request_type_id", limit: 4,     null: false
    t.string   "request_option",  limit: 255,   null: false
    t.text     "valid_options",   limit: 65535, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_types", force: :cascade do |t|
    t.string   "key",                limit: 100
    t.string   "name",               limit: 255
    t.integer  "workflow_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "asset_type",         limit: 255
    t.integer  "order",              limit: 4
    t.string   "initial_state",      limit: 20
    t.string   "target_asset_type",  limit: 255
    t.boolean  "multiples_allowed",                default: false
    t.string   "request_class_name", limit: 255
    t.text     "request_parameters", limit: 65535
    t.integer  "morphology",         limit: 4,     default: 0
    t.boolean  "for_multiplexing",                 default: false
    t.boolean  "billable",                         default: false
    t.integer  "product_line_id",    limit: 4
    t.boolean  "deprecated",                       default: false, null: false
    t.boolean  "no_target_asset",                  default: false, null: false
    t.integer  "target_purpose_id",  limit: 4
    t.integer  "pooling_method_id",  limit: 4
    t.integer  "request_purpose_id", limit: 4
  end

  create_table "request_types_extended_validators", force: :cascade do |t|
    t.integer  "request_type_id",       limit: 4, null: false
    t.integer  "extended_validator_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "request_types_extended_validators", ["extended_validator_id"], name: "fk_request_types_extended_validators_to_extended_validators", using: :btree
  add_index "request_types_extended_validators", ["request_type_id"], name: "fk_request_types_extended_validators_to_request_types", using: :btree

  create_table "requests", force: :cascade do |t|
    t.integer  "initial_study_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",            limit: 4
    t.string   "state",              limit: 20,  default: "pending"
    t.integer  "sample_pool_id",     limit: 4
    t.integer  "workflow_id",        limit: 4
    t.integer  "request_type_id",    limit: 4
    t.integer  "item_id",            limit: 4
    t.integer  "asset_id",           limit: 4
    t.integer  "target_asset_id",    limit: 4
    t.integer  "pipeline_id",        limit: 4
    t.integer  "submission_id",      limit: 4
    t.boolean  "charge"
    t.integer  "initial_project_id", limit: 4
    t.integer  "priority",           limit: 4,   default: 0
    t.string   "sti_type",           limit: 255
    t.integer  "order_id",           limit: 4
    t.integer  "request_purpose_id", limit: 4
  end

  add_index "requests", ["asset_id"], name: "index_requests_on_asset_id", using: :btree
  add_index "requests", ["initial_project_id"], name: "index_requests_on_project_id", using: :btree
  add_index "requests", ["initial_study_id", "request_type_id", "state"], name: "index_requests_on_project_id_and_request_type_id_and_state", using: :btree
  add_index "requests", ["initial_study_id"], name: "index_request_on_project_id", using: :btree
  add_index "requests", ["item_id"], name: "index_request_on_item_id", using: :btree
  add_index "requests", ["request_type_id", "state"], name: "request_type_id_state_index", using: :btree
  add_index "requests", ["state", "request_type_id", "initial_study_id"], name: "request_project_index", using: :btree
  add_index "requests", ["submission_id"], name: "index_requests_on_submission_id", using: :btree
  add_index "requests", ["target_asset_id"], name: "index_requests_on_target_asset_id", using: :btree
  add_index "requests", ["updated_at"], name: "index_requests_on_updated_at", using: :btree

  create_table "robot_properties", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "value",      limit: 255
    t.string   "key",        limit: 50
    t.integer  "robot_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "robots", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "location",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "barcode",        limit: 255
    t.float    "minimum_volume", limit: 24
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "authorizable_type", limit: 50
    t.integer  "authorizable_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["authorizable_id", "authorizable_type"], name: "index_roles_on_authorizable_id_and_authorizable_type", using: :btree
  add_index "roles", ["authorizable_id"], name: "index_roles_on_authorizable_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "roles_users", force: :cascade do |t|
    t.integer  "role_id",    limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "roles_users", ["role_id"], name: "index_roles_users_on_role_id", using: :btree
  add_index "roles_users", ["user_id"], name: "index_roles_users_on_user_id", using: :btree

  create_table "sample_manifests", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "study_id",    limit: 4
    t.integer  "project_id",  limit: 4
    t.integer  "supplier_id", limit: 4
    t.integer  "count",       limit: 4
    t.string   "asset_type",  limit: 255
    t.text     "last_errors", limit: 65535
    t.string   "state",       limit: 255
    t.text     "barcodes",    limit: 65535
    t.integer  "user_id",     limit: 4
    t.string   "password",    limit: 255
  end

  add_index "sample_manifests", ["asset_type"], name: "index_sample_manifests_on_asset_type", using: :btree
  add_index "sample_manifests", ["created_at"], name: "index_sample_manifests_on_created_at", using: :btree
  add_index "sample_manifests", ["study_id"], name: "index_sample_manifests_on_study_id", using: :btree
  add_index "sample_manifests", ["supplier_id"], name: "index_sample_manifests_on_supplier_id", using: :btree
  add_index "sample_manifests", ["updated_at"], name: "index_sample_manifests_on_updated_at", using: :btree
  add_index "sample_manifests", ["user_id"], name: "index_sample_manifests_on_user_id", using: :btree

  create_table "sample_metadata", force: :cascade do |t|
    t.integer  "sample_id",                   limit: 4
    t.string   "organism",                    limit: 255
    t.string   "gc_content",                  limit: 255
    t.string   "cohort",                      limit: 255
    t.string   "gender",                      limit: 255
    t.string   "country_of_origin",           limit: 255
    t.string   "geographical_region",         limit: 255
    t.string   "ethnicity",                   limit: 255
    t.string   "dna_source",                  limit: 255
    t.string   "volume",                      limit: 255
    t.string   "supplier_plate_id",           limit: 255
    t.string   "mother",                      limit: 255
    t.string   "father",                      limit: 255
    t.string   "replicate",                   limit: 255
    t.string   "sample_public_name",          limit: 255
    t.string   "sample_common_name",          limit: 255
    t.string   "sample_strain_att",           limit: 255
    t.integer  "sample_taxon_id",             limit: 4
    t.string   "sample_ebi_accession_number", limit: 255
    t.string   "sample_sra_hold",             limit: 255
    t.string   "sample_reference_genome_old", limit: 255
    t.text     "sample_description",          limit: 65535
    t.string   "sibling",                     limit: 255
    t.boolean  "is_resubmitted"
    t.string   "date_of_sample_collection",   limit: 255
    t.string   "date_of_sample_extraction",   limit: 255
    t.string   "sample_extraction_method",    limit: 255
    t.string   "sample_purified",             limit: 255
    t.string   "purification_method",         limit: 255
    t.string   "concentration",               limit: 255
    t.string   "concentration_determined_by", limit: 255
    t.string   "sample_type",                 limit: 255
    t.string   "sample_storage_conditions",   limit: 255
    t.string   "supplier_name",               limit: 255
    t.integer  "reference_genome_id",         limit: 4,     default: 1
    t.string   "genotype",                    limit: 255
    t.string   "phenotype",                   limit: 255
    t.string   "age",                         limit: 255
    t.string   "developmental_stage",         limit: 255
    t.string   "cell_type",                   limit: 255
    t.string   "disease_state",               limit: 255
    t.string   "compound",                    limit: 255
    t.string   "dose",                        limit: 255
    t.string   "immunoprecipitate",           limit: 255
    t.string   "growth_condition",            limit: 255
    t.string   "rnai",                        limit: 255
    t.string   "organism_part",               limit: 255
    t.string   "time_point",                  limit: 255
    t.string   "disease",                     limit: 255
    t.string   "subject",                     limit: 255
    t.string   "treatment",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "donor_id",                    limit: 255
  end

  add_index "sample_metadata", ["sample_ebi_accession_number"], name: "index_sample_metadata_on_sample_ebi_accession_number", using: :btree
  add_index "sample_metadata", ["sample_id"], name: "index_sample_metadata_on_sample_id", using: :btree
  add_index "sample_metadata", ["supplier_name"], name: "index_sample_metadata_on_supplier_name", using: :btree

  create_table "sample_registrars", force: :cascade do |t|
    t.integer "study_id",       limit: 4
    t.integer "user_id",        limit: 4
    t.integer "sample_id",      limit: 4
    t.integer "sample_tube_id", limit: 4
    t.integer "asset_group_id", limit: 4
  end

  create_table "samples", force: :cascade do |t|
    t.string   "name",                       limit: 255
    t.boolean  "new_name_format",                        default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sanger_sample_id",           limit: 255
    t.integer  "sample_manifest_id",         limit: 4
    t.boolean  "control"
    t.boolean  "empty_supplier_sample_name",             default: false
    t.boolean  "updated_by_manifest",                    default: false
    t.boolean  "consent_withdrawn",                      default: false, null: false
  end

  add_index "samples", ["created_at"], name: "index_samples_on_created_at", using: :btree
  add_index "samples", ["name"], name: "index_samples_on_name", using: :btree
  add_index "samples", ["sample_manifest_id"], name: "index_samples_on_sample_manifest_id", using: :btree
  add_index "samples", ["sanger_sample_id"], name: "index_samples_on_sanger_sample_id", using: :btree
  add_index "samples", ["updated_at"], name: "index_samples_on_updated_at", using: :btree

  create_table "sanger_sample_ids", force: :cascade do |t|
  end

  create_table "searches", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "type",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "target_model_name",  limit: 255
    t.text     "default_parameters", limit: 65535
  end

  create_table "specific_tube_creation_purposes", force: :cascade do |t|
    t.integer  "specific_tube_creation_id", limit: 4
    t.integer  "tube_purpose_id",           limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stamp_qcables", force: :cascade do |t|
    t.integer  "stamp_id",   limit: 4,   null: false
    t.integer  "qcable_id",  limit: 4,   null: false
    t.string   "bed",        limit: 255, null: false
    t.integer  "order",      limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stamp_qcables", ["qcable_id"], name: "fk_stamp_qcables_to_qcables", using: :btree
  add_index "stamp_qcables", ["stamp_id"], name: "fk_stamp_qcables_to_stamps", using: :btree

  create_table "stamps", force: :cascade do |t|
    t.integer  "lot_id",     limit: 4,   null: false
    t.integer  "user_id",    limit: 4,   null: false
    t.integer  "robot_id",   limit: 4,   null: false
    t.string   "tip_lot",    limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stamps", ["lot_id"], name: "fk_stamps_to_lots", using: :btree
  add_index "stamps", ["robot_id"], name: "fk_stamps_to_robots", using: :btree
  add_index "stamps", ["user_id"], name: "fk_stamps_to_users", using: :btree

  create_table "state_changes", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "target_id",      limit: 4
    t.string   "contents",       limit: 1024
    t.string   "previous_state", limit: 255
    t.string   "target_state",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reason",         limit: 255
  end

  create_table "studies", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",              limit: 4
    t.boolean  "blocked",                          default: false
    t.string   "state",                limit: 20
    t.boolean  "ethically_approved"
    t.boolean  "enforce_data_release",             default: true
    t.boolean  "enforce_accessioning",             default: true
    t.integer  "reference_genome_id",  limit: 4,   default: 1
  end

  add_index "studies", ["ethically_approved"], name: "index_studies_on_ethically_approved", using: :btree
  add_index "studies", ["state"], name: "index_studies_on_state", using: :btree
  add_index "studies", ["updated_at"], name: "index_studies_on_updated_at", using: :btree
  add_index "studies", ["user_id"], name: "index_projects_on_user_id", using: :btree

  create_table "study_metadata", force: :cascade do |t|
    t.integer  "study_id",                               limit: 4
    t.string   "old_sac_sponsor",                        limit: 255
    t.text     "study_description",                      limit: 65535
    t.string   "contaminated_human_dna",                 limit: 255
    t.string   "study_project_id",                       limit: 255
    t.text     "study_abstract",                         limit: 65535
    t.string   "study_study_title",                      limit: 255
    t.string   "study_ebi_accession_number",             limit: 255
    t.string   "study_sra_hold",                         limit: 255
    t.string   "contains_human_dna",                     limit: 255
    t.string   "study_name_abbreviation",                limit: 255
    t.string   "reference_genome_old",                   limit: 255
    t.string   "data_release_strategy",                  limit: 255
    t.string   "data_release_standard_agreement",        limit: 255
    t.string   "data_release_timing",                    limit: 255
    t.string   "data_release_delay_reason",              limit: 255
    t.string   "data_release_delay_other_comment",       limit: 255
    t.string   "data_release_delay_period",              limit: 255
    t.string   "data_release_delay_approval",            limit: 255
    t.string   "data_release_delay_reason_comment",      limit: 255
    t.string   "data_release_prevention_reason",         limit: 255
    t.string   "data_release_prevention_approval",       limit: 255
    t.string   "data_release_prevention_reason_comment", limit: 255
    t.integer  "snp_study_id",                           limit: 4
    t.integer  "snp_parent_study_id",                    limit: 4
    t.boolean  "bam",                                                  default: true
    t.integer  "study_type_id",                          limit: 4
    t.integer  "data_release_study_type_id",             limit: 4
    t.integer  "reference_genome_id",                    limit: 4,     default: 1
    t.string   "array_express_accession_number",         limit: 255
    t.text     "dac_policy",                             limit: 65535
    t.string   "ega_policy_accession_number",            limit: 255
    t.string   "ega_dac_accession_number",               limit: 255
    t.string   "commercially_available",                 limit: 255,   default: "No"
    t.integer  "faculty_sponsor_id",                     limit: 4
    t.float    "number_of_gigabases_per_sample",         limit: 24
    t.string   "hmdmc_approval_number",                  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remove_x_and_autosomes",                 limit: 255,   default: "No",  null: false
    t.string   "dac_policy_title",                       limit: 255
    t.boolean  "separate_y_chromosome_data",                           default: false, null: false
    t.string   "data_access_group",                      limit: 255
    t.string   "prelim_id",                              limit: 255
    t.integer  "program_id",                             limit: 4
  end

  add_index "study_metadata", ["faculty_sponsor_id"], name: "index_study_metadata_on_faculty_sponsor_id", using: :btree
  add_index "study_metadata", ["prelim_id"], name: "index_study_metadata_on_prelim_id", using: :btree
  add_index "study_metadata", ["study_id"], name: "index_study_metadata_on_study_id", using: :btree

  create_table "study_relation_types", force: :cascade do |t|
    t.string "name",          limit: 255
    t.string "reversed_name", limit: 255
  end

  create_table "study_relations", force: :cascade do |t|
    t.integer "study_id",               limit: 4
    t.integer "related_study_id",       limit: 4
    t.integer "study_relation_type_id", limit: 4
  end

  add_index "study_relations", ["related_study_id"], name: "index_study_relations_on_related_study_id", using: :btree
  add_index "study_relations", ["study_id"], name: "index_study_relations_on_study_id", using: :btree

  create_table "study_reports", force: :cascade do |t|
    t.integer  "study_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",         limit: 4
    t.string   "report_filename", limit: 255
    t.string   "content_type",    limit: 255, default: "text/csv"
  end

  add_index "study_reports", ["created_at"], name: "index_study_reports_on_created_at", using: :btree
  add_index "study_reports", ["study_id"], name: "index_study_reports_on_study_id", using: :btree
  add_index "study_reports", ["updated_at"], name: "index_study_reports_on_updated_at", using: :btree
  add_index "study_reports", ["user_id"], name: "index_study_reports_on_user_id", using: :btree

  create_table "study_samples", force: :cascade do |t|
    t.integer  "study_id",   limit: 4, null: false
    t.integer  "sample_id",  limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "study_samples", ["sample_id", "study_id"], name: "unique_samples_in_studies_idx", unique: true, using: :btree
  add_index "study_samples", ["sample_id"], name: "index_project_samples_on_sample_id", using: :btree
  add_index "study_samples", ["study_id"], name: "index_project_samples_on_project_id", using: :btree

  create_table "study_samples_backup", id: false, force: :cascade do |t|
    t.integer "id",        limit: 4, default: 0, null: false
    t.integer "study_id",  limit: 4
    t.integer "sample_id", limit: 4
  end

  create_table "study_types", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.boolean  "valid_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "valid_for_creation",             default: true, null: false
  end

  create_table "subclass_attributes", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "value",             limit: 255
    t.integer  "attributable_id",   limit: 4
    t.string   "attributable_type", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subclass_attributes", ["attributable_id", "name"], name: "index_subclass_attributes_on_attributable_id_and_name", using: :btree

  create_table "submission_templates", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "submission_class_name", limit: 255
    t.text     "submission_parameters", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_line_id",       limit: 4
    t.integer  "superceded_by_id",      limit: 4,     default: -1, null: false
    t.datetime "superceded_at"
    t.integer  "product_catalogue_id",  limit: 4
  end

  add_index "submission_templates", ["name", "superceded_by_id"], name: "name_and_superceded_by_unique_idx", unique: true, using: :btree
  add_index "submission_templates", ["product_catalogue_id"], name: "fk_submission_templates_to_product_catalogues", using: :btree

  create_table "submission_workflows", force: :cascade do |t|
    t.string   "key",        limit: 50
    t.string   "name",       limit: 255
    t.string   "item_label", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                  limit: 20
    t.string   "message",                limit: 255
    t.integer  "user_id",                limit: 4
    t.text     "request_types",          limit: 65535
    t.text     "request_options",        limit: 65535
    t.string   "name",                   limit: 255
    t.integer  "priority",               limit: 1,     default: 0, null: false
    t.integer  "submission_template_id", limit: 4
  end

  add_index "submissions", ["name"], name: "index_submissions_on_name", using: :btree
  add_index "submissions", ["state"], name: "index_submissions_on_state", using: :btree

  create_table "submitted_assets", force: :cascade do |t|
    t.integer  "order_id",   limit: 4
    t.integer  "asset_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "submitted_assets", ["asset_id"], name: "index_submitted_assets_on_asset_id", using: :btree

  create_table "suppliers", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",        limit: 255
    t.string   "address",      limit: 255
    t.string   "contact_name", limit: 255
    t.string   "phone_number", limit: 255
    t.string   "fax",          limit: 255
    t.string   "supplier_url", limit: 255
    t.string   "abbreviation", limit: 255
  end

  add_index "suppliers", ["abbreviation"], name: "index_suppliers_on_abbreviation", using: :btree
  add_index "suppliers", ["created_at"], name: "index_suppliers_on_created_at", using: :btree
  add_index "suppliers", ["name"], name: "index_suppliers_on_name", using: :btree
  add_index "suppliers", ["updated_at"], name: "index_suppliers_on_updated_at", using: :btree

  create_table "tag2_layout_template_submissions", force: :cascade do |t|
    t.integer  "submission_id",           limit: 4, null: false
    t.integer  "tag2_layout_template_id", limit: 4, null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "tag2_layout_template_submissions", ["submission_id", "tag2_layout_template_id"], name: "tag2_layouts_used_once_per_submission", unique: true, using: :btree
  add_index "tag2_layout_template_submissions", ["tag2_layout_template_id"], name: "fk_tag2_layout_template_submissions_to_tag2_layout_templates", using: :btree

  create_table "tag2_layout_templates", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.integer  "tag_id",     limit: 4,   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "tag2_layouts", force: :cascade do |t|
    t.integer  "tag_id",                limit: 4
    t.integer  "plate_id",              limit: 4
    t.integer  "user_id",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id",             limit: 4
    t.text     "target_well_locations", limit: 65535
  end

  create_table "tag_groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",                default: true
  end

  add_index "tag_groups", ["name"], name: "tag_groups_unique_name", unique: true, using: :btree

  create_table "tag_layout_templates", force: :cascade do |t|
    t.string   "direction_algorithm", limit: 255
    t.integer  "tag_group_id",        limit: 4
    t.string   "name",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "walking_algorithm",   limit: 255, default: "TagLayout::WalkWellsByPools"
  end

  create_table "tag_layouts", force: :cascade do |t|
    t.string   "direction_algorithm", limit: 255
    t.integer  "tag_group_id",        limit: 4
    t.integer  "plate_id",            limit: 4
    t.integer  "user_id",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "substitutions",       limit: 1525
    t.string   "walking_algorithm",   limit: 255,  default: "TagLayout::WalkWellsByPools"
    t.integer  "initial_tag",         limit: 4,    default: 0,                             null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string   "oligo",        limit: 255
    t.integer  "map_id",       limit: 4
    t.integer  "tag_group_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["map_id"], name: "index_tags_on_map_id", using: :btree
  add_index "tags", ["tag_group_id"], name: "index_tags_on_tag_group_id", using: :btree
  add_index "tags", ["updated_at"], name: "index_tags_on_updated_at", using: :btree

  create_table "task_request_types", force: :cascade do |t|
    t.integer  "task_id",         limit: 4
    t.integer  "request_type_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order",           limit: 4
  end

  add_index "task_request_types", ["request_type_id"], name: "index_task_request_types_on_request_type_id", using: :btree
  add_index "task_request_types", ["task_id"], name: "index_task_request_types_on_task_id", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.string  "name",                 limit: 255
    t.integer "pipeline_workflow_id", limit: 4
    t.integer "sorted",               limit: 4
    t.boolean "batched"
    t.string  "location",             limit: 255
    t.boolean "interactive"
    t.boolean "per_item"
    t.string  "sti_type",             limit: 50
    t.boolean "lab_activity"
    t.integer "purpose_id",           limit: 4
  end

  add_index "tasks", ["name"], name: "index_tasks_on_name", using: :btree
  add_index "tasks", ["pipeline_workflow_id"], name: "index_tasks_on_pipeline_workflow_id", using: :btree
  add_index "tasks", ["sorted"], name: "index_tasks_on_sorted", using: :btree
  add_index "tasks", ["sti_type"], name: "index_tasks_on_sti_type", using: :btree

  create_table "transfer_templates", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                limit: 255
    t.string   "transfer_class_name", limit: 255
    t.string   "transfers",           limit: 1024
  end

  create_table "transfers", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sti_type",         limit: 255
    t.integer  "source_id",        limit: 4
    t.integer  "destination_id",   limit: 4
    t.string   "destination_type", limit: 255
    t.text     "transfers",        limit: 65535
    t.integer  "bulk_transfer_id", limit: 4
    t.integer  "user_id",          limit: 4
  end

  add_index "transfers", ["source_id"], name: "source_id_idx", using: :btree

  create_table "tube_creation_children", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tube_creation_id", limit: 4, null: false
    t.integer  "tube_id",          limit: 4, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",                     limit: 255
    t.string   "email",                     limit: 255
    t.string   "crypted_password",          limit: 40
    t.string   "salt",                      limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            limit: 255
    t.datetime "remember_token_expires_at"
    t.string   "api_key",                   limit: 255
    t.string   "first_name",                limit: 255
    t.string   "last_name",                 limit: 255
    t.integer  "workflow_id",               limit: 4
    t.boolean  "pipeline_administrator"
    t.string   "barcode",                   limit: 255
    t.string   "cookie",                    limit: 255
    t.datetime "cookie_validated_at"
    t.string   "encrypted_swipecard_code",  limit: 40
  end

  add_index "users", ["barcode"], name: "index_users_on_barcode", using: :btree
  add_index "users", ["encrypted_swipecard_code"], name: "index_users_on_encrypted_swipecard_code", using: :btree
  add_index "users", ["login"], name: "index_users_on_login", using: :btree
  add_index "users", ["pipeline_administrator"], name: "index_users_on_pipeline_administrator", using: :btree

  create_table "uuids", force: :cascade do |t|
    t.string  "resource_type", limit: 128, null: false
    t.integer "resource_id",   limit: 4,   null: false
    t.string  "external_id",   limit: 36,  null: false
  end

  add_index "uuids", ["external_id"], name: "index_uuids_on_external_id", using: :btree
  add_index "uuids", ["resource_type", "resource_id"], name: "index_uuids_on_resource_type_and_resource_id", using: :btree

  create_table "volume_updates", force: :cascade do |t|
    t.integer  "target_id",     limit: 4
    t.string   "created_by",    limit: 255
    t.float    "volume_change", limit: 24
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "well_attributes", force: :cascade do |t|
    t.integer  "well_id",                      limit: 4
    t.string   "gel_pass",                     limit: 20
    t.float    "concentration",                limit: 24
    t.float    "current_volume",               limit: 24
    t.float    "buffer_volume",                limit: 24
    t.float    "requested_volume",             limit: 24
    t.float    "picked_volume",                limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pico_pass",                    limit: 255, default: "ungraded", null: false
    t.integer  "sequenom_count",               limit: 4
    t.string   "study_id",                     limit: 255
    t.string   "gender_markers",               limit: 255
    t.string   "gender",                       limit: 255
    t.float    "measured_volume",              limit: 24
    t.float    "initial_volume",               limit: 24
    t.float    "molarity",                     limit: 24
    t.float    "rin",                          limit: 24
    t.float    "robot_minimum_picking_volume", limit: 24
  end

  add_index "well_attributes", ["well_id"], name: "index_well_attributes_on_well_id", using: :btree

  create_table "well_links", force: :cascade do |t|
    t.integer "target_well_id", limit: 4,   null: false
    t.integer "source_well_id", limit: 4,   null: false
    t.string  "type",           limit: 255, null: false
  end

  add_index "well_links", ["target_well_id"], name: "target_well_idx", using: :btree

  create_table "well_to_tube_transfers", force: :cascade do |t|
    t.integer "transfer_id",    limit: 4,   null: false
    t.integer "destination_id", limit: 4,   null: false
    t.string  "source",         limit: 255
  end

  create_table "work_completions", force: :cascade do |t|
    t.integer  "user_id",    limit: 4, null: false
    t.integer  "target_id",  limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_completions", ["target_id"], name: "fk_rails_f8fb9e95de", using: :btree
  add_index "work_completions", ["user_id"], name: "fk_rails_204fc81a92", using: :btree

  create_table "work_completions_submissions", force: :cascade do |t|
    t.integer "work_completion_id", limit: 4, null: false
    t.integer "submission_id",      limit: 4, null: false
  end

  add_index "work_completions_submissions", ["submission_id"], name: "fk_rails_1ac4e93988", using: :btree
  add_index "work_completions_submissions", ["work_completion_id"], name: "fk_rails_5ea64f1af2", using: :btree

  create_table "workflow_samples", force: :cascade do |t|
    t.text     "name",          limit: 65535
    t.integer  "user_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "control",                     default: false
    t.integer  "workflow_id",   limit: 4
    t.integer  "submission_id", limit: 4
    t.string   "state",         limit: 20
    t.integer  "size",          limit: 4,     default: 1
    t.integer  "version",       limit: 4
  end

  add_foreign_key "work_completions", "assets", column: "target_id"
  add_foreign_key "work_completions", "users"
  add_foreign_key "work_completions_submissions", "submissions"
  add_foreign_key "work_completions_submissions", "work_completions"
end
