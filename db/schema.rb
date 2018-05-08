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

ActiveRecord::Schema.define(version: 20180502101116) do

  create_table "aker_containers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "barcode"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "aker_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "aker_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "aliquot_indices", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "aliquot_id", null: false
    t.integer "lane_id", null: false
    t.integer "aliquot_index", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aliquot_id"], name: "index_aliquot_indices_on_aliquot_id", unique: true
    t.index ["lane_id", "aliquot_index"], name: "index_aliquot_indices_on_lane_id_and_aliquot_index", unique: true
  end

  create_table "aliquots", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "receptacle_id", null: false
    t.integer "study_id"
    t.integer "project_id"
    t.integer "library_id"
    t.integer "sample_id", null: false
    t.integer "tag_id"
    t.string "library_type"
    t.integer "insert_size_from"
    t.integer "insert_size_to"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bait_library_id"
    t.integer "tag2_id", default: -1
    t.boolean "suboptimal", default: false, null: false
    t.bigint "primer_panel_id"
    t.index ["library_id"], name: "index_aliquots_on_library_id"
    t.index ["primer_panel_id"], name: "index_aliquots_on_primer_panel_id"
    t.index ["receptacle_id", "tag_id", "tag2_id"], name: "aliquot_tags_and_tag2s_are_unique_within_receptacle", unique: true
    t.index ["sample_id"], name: "index_aliquots_on_sample_id"
    t.index ["study_id"], name: "index_aliquots_on_study_id"
    t.index ["tag_id"], name: "tag_id_idx"
  end

  create_table "api_applications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.string "key", null: false
    t.string "contact", null: false
    t.text "description"
    t.string "privilege", null: false
    t.index ["key"], name: "index_api_applications_on_key"
  end

  create_table "archived_properties", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.text "value"
    t.string "propertied_type"
    t.integer "user_id"
    t.string "key", limit: 50
    t.integer "propertied_id"
  end

  create_table "asset_audits", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "message"
    t.string "key"
    t.string "created_by"
    t.integer "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "witnessed_by"
    t.index ["asset_id"], name: "index_asset_audits_on_asset_id"
  end

  create_table "asset_barcodes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
  end

  create_table "asset_creation_parents", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "asset_creation_id"
    t.integer "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "asset_creations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "parent_id"
    t.integer "child_purpose_id"
    t.integer "child_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", null: false
  end

  create_table "asset_group_assets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "asset_id"
    t.integer "asset_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["asset_group_id"], name: "index_asset_group_assets_on_asset_group_id"
    t.index ["asset_id"], name: "index_asset_group_assets_on_asset_id"
  end

  create_table "asset_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "user_id"
    t.integer "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "asset_links", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.boolean "direct"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestor_id", "direct"], name: "index_asset_links_on_ancestor_id_and_direct"
    t.index ["descendant_id", "direct"], name: "index_asset_links_on_descendant_id_and_direct"
  end

  create_table "asset_shapes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.integer "horizontal_ratio", null: false
    t.integer "vertical_ratio", null: false
    t.string "description_strategy", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "value"
    t.text "descriptors"
    t.text "descriptor_fields"
    t.string "sti_type", limit: 50
    t.string "barcode"
    t.string "qc_state", limit: 20
    t.boolean "resource"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "map_id"
    t.integer "size"
    t.boolean "closed", default: false
    t.string "public_name"
    t.boolean "archive"
    t.boolean "external_release"
    t.string "two_dimensional_barcode"
    t.integer "plate_purpose_id"
    t.decimal "volume", precision: 10, scale: 2
    t.integer "barcode_prefix_id"
    t.decimal "concentration", precision: 18, scale: 8
    t.integer "legacy_sample_id"
    t.integer "legacy_tag_id"
    t.index ["barcode"], name: "index_assets_on_barcode"
    t.index ["barcode_prefix_id"], name: "index_assets_on_barcode_prefix_id"
    t.index ["sti_type", "plate_purpose_id"], name: "index_assets_on_plate_purpose_id_sti_type"
    t.index ["sti_type", "updated_at"], name: "index_assets_on_sti_type_and_updated_at"
    t.index ["sti_type"], name: "index_assets_on_sti_type"
    t.index ["updated_at"], name: "index_assets_on_updated_at"
  end

  create_table "attachments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "pipeline_workflow_id"
    t.integer "attachable_id"
    t.string "attachable_type", limit: 50
    t.integer "position"
  end

  create_table "audits", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "changes"
    t.integer "version", default: 0
    t.datetime "created_at"
  end

  create_table "bait_libraries", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "bait_library_supplier_id"
    t.string "name", null: false
    t.string "supplier_identifier"
    t.string "target_species", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "bait_library_type_id", null: false
    t.boolean "visible", default: true, null: false
    t.index ["bait_library_supplier_id", "name"], name: "bait_library_names_are_unique_within_a_supplier", unique: true
  end

  create_table "bait_library_layouts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "plate_id", null: false
    t.string "layout", limit: 1024
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["plate_id"], name: "bait_libraries_are_laid_out_on_a_plate_once", unique: true
  end

  create_table "bait_library_suppliers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "visible", default: true, null: false
  end

  create_table "bait_library_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "visible", default: true, null: false
    t.integer "category"
    t.index ["name"], name: "index_bait_library_types_on_name", unique: true
  end

  create_table "barcode_prefixes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "prefix", limit: 3
    t.index ["prefix"], name: "index_barcode_prefixes_on_prefix"
  end

  create_table "barcode_printer_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "printer_type_id"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "label_template_name"
    t.index ["name"], name: "index_barcode_printer_types_on_name"
    t.index ["type"], name: "index_barcode_printer_types_on_type"
  end

  create_table "barcode_printers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "barcode_printer_type_id"
  end

  create_table "batch_requests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "batch_id", null: false
    t.integer "request_id", null: false
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["batch_id"], name: "index_batch_requests_on_batch_id"
    t.index ["request_id"], name: "request_id", unique: true
  end

  create_table "batches", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "item_limit"
    t.datetime "created_at"
    t.integer "user_id"
    t.datetime "updated_at"
    t.integer "pipeline_id"
    t.string "state", limit: 20
    t.integer "assignee_id"
    t.integer "qc_pipeline_id"
    t.string "production_state"
    t.string "qc_state", limit: 25
    t.string "barcode"
    t.index ["pipeline_id", "state", "created_at"], name: "index_batches_on_pipeline_id_and_state_and_created_at"
    t.index ["updated_at"], name: "index_batches_on_updated_at"
  end

  create_table "billing_events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "kind", default: "charge", null: false
    t.datetime "entry_date", null: false
    t.string "created_by", null: false
    t.integer "project_id", null: false
    t.string "reference", null: false
    t.string "description", default: "Unspecified"
    t.float "quantity", limit: 24, default: 1.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "request_id", null: false
  end

  create_table "billing_items", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "request_id"
    t.string "project_cost_code"
    t.string "units"
    t.string "billing_product_code"
    t.string "billing_product_name"
    t.string "billing_product_description"
    t.string "request_passed_date"
    t.timestamp "reported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["request_id"], name: "index_billing_items_on_request_id"
  end

  create_table "billing_product_catalogues", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "billing_products", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "identifier"
    t.integer "category"
    t.integer "billing_product_catalogue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_product_catalogue_id"], name: "fk_rails_01eabb683d"
  end

  create_table "broadcast_events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "sti_type"
    t.string "seed_type"
    t.integer "seed_id"
    t.integer "user_id"
    t.text "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "budget_divisions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bulk_transfers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "title"
    t.string "commentable_type", limit: 50
    t.integer "user_id"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "commentable_id", null: false
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
  end

  create_table "container_associations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "container_id", null: false
    t.integer "content_id", null: false
    t.index ["container_id"], name: "index_container_associations_on_container_id"
    t.index ["content_id"], name: "container_association_content_is_unique", unique: true
  end

  create_table "controls", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "item_id"
    t.integer "pipeline_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "key"
    t.string "value"
    t.integer "custom_metadatum_collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_metadatum_collection_id"], name: "index_custom_metadata_on_custom_metadatum_collection_id"
  end

  create_table "custom_metadatum_collections", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_custom_metadatum_collections_on_asset_id"
  end

  create_table "custom_texts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "identifier"
    t.integer "differential"
    t.string "content_type"
    t.text "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_release_study_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "for_array_express", default: false
    t.boolean "is_default", default: false
    t.boolean "is_assay_type", default: false
  end

  create_table "db_files", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.binary "data", limit: 4294967295
    t.integer "owner_id"
    t.string "owner_type", limit: 25, default: "Document", null: false
    t.string "owner_type_extended"
    t.index ["owner_type", "owner_id"], name: "index_db_files_on_owner_type_and_owner_id"
  end

  create_table "delayed_jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "queue"
  end

  create_table "depricated_attempts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "state", limit: 20, default: "pending"
    t.integer "request_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "workflow_id"
  end

  create_table "descriptors", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "value"
    t.text "selection"
    t.integer "task_id"
    t.string "kind"
    t.boolean "required"
    t.integer "sorter"
    t.integer "family_id"
    t.string "key", limit: 50
    t.index ["task_id"], name: "index_descriptors_on_task_id"
  end

  create_table "documents", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "documentable_id"
    t.integer "size"
    t.string "content_type"
    t.string "filename"
    t.integer "height"
    t.integer "width"
    t.integer "parent_id"
    t.string "thumbnail"
    t.integer "db_file_id"
    t.string "documentable_type", limit: 50, null: false
    t.string "documentable_extended", limit: 50
    t.index ["documentable_id", "documentable_type"], name: "index_documents_on_documentable_id_and_documentable_type"
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable_type_and_documentable_id"
  end

  create_table "documents_shadow", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "documentable_id"
    t.integer "size"
    t.string "content_type"
    t.string "filename"
    t.integer "height"
    t.integer "width"
    t.integer "parent_id"
    t.string "thumbnail"
    t.integer "db_file_id"
    t.string "documentable_type", limit: 50
  end

  create_table "equipment", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "equipment_type"
    t.string "prefix", limit: 2, null: false
    t.string "ean13_barcode", limit: 13
  end

  create_table "events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "eventful_id"
    t.string "eventful_type", limit: 50
    t.string "message"
    t.string "family"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "identifier"
    t.string "location"
    t.boolean "actioned"
    t.text "content"
    t.string "created_by"
    t.string "of_interest_to"
    t.string "descriptor_key", limit: 50
    t.string "type", default: "Event"
    t.index ["eventful_id"], name: "index_events_on_eventful_id"
    t.index ["eventful_type"], name: "index_events_on_eventful_type"
  end

  create_table "extended_validators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "behaviour", null: false
    t.text "options"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_properties", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "propertied_id"
    t.string "propertied_type", limit: 50
    t.string "key", limit: 50
    t.string "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["propertied_id", "propertied_type", "key"], name: "ep_pi_pt_key"
  end

  create_table "extraction_attributes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "target_id"
    t.string "created_by"
    t.text "attributes_update", limit: 4294967295
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "faculty_sponsors", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "failures", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "failable_id"
    t.string "failable_type", limit: 50
    t.text "reason"
    t.boolean "notify_remote"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "comment"
    t.index ["failable_id"], name: "index_failures_on_failable_id"
  end

  create_table "families", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.text "description"
    t.string "relates_to"
    t.integer "task_id"
    t.integer "pipeline_workflow_id"
  end

  create_table "identifiers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "identifiable_id"
    t.string "identifiable_type", limit: 50
    t.string "resource_name"
    t.integer "external_id"
    t.string "external_type", limit: 50
    t.boolean "do_not_sync", default: false
    t.index ["external_id", "identifiable_id"], name: "index_identifiers_on_external_id_and_identifiable_id"
    t.index ["external_type"], name: "index_identifiers_on_external_type"
    t.index ["identifiable_id", "identifiable_type"], name: "index_identifiers_on_identifiable_id_and_identifiable_type"
    t.index ["resource_name"], name: "index_identifiers_on_resource_name"
  end

  create_table "implements", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "barcode"
    t.string "equipment_type"
  end

  create_table "items", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "study_id"
    t.integer "user_id"
    t.integer "count"
    t.integer "workflow_sample_id"
    t.boolean "closed", default: false
    t.integer "pool_id"
    t.integer "version"
    t.integer "submission_id"
    t.index ["name"], name: "index_items_on_name"
    t.index ["version"], name: "index_items_on_version"
  end

  create_table "lab_events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.text "description"
    t.text "descriptors"
    t.text "descriptor_fields"
    t.integer "eventful_id"
    t.string "eventful_type", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "filename"
    t.binary "data"
    t.text "message"
    t.integer "user_id"
    t.integer "batch_id"
    t.index ["batch_id"], name: "index_lab_events_on_batch_id"
    t.index ["description", "eventful_type"], name: "index_lab_events_find_flowcell", length: { description: 20 }
    t.index ["eventful_id"], name: "index_lab_events_on_eventful_id"
    t.index ["eventful_type"], name: "index_lab_events_on_eventful_type"
  end

  create_table "lane_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "lane_id"
    t.string "release_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "library_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "library_types_request_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_type_id", null: false
    t.integer "library_type_id", null: false
    t.boolean "is_default", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["library_type_id"], name: "fk_library_types_request_types_to_library_types"
    t.index ["request_type_id"], name: "fk_library_types_request_types_to_request_types"
  end

  create_table "location_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "report_type", null: false
    t.string "barcodes"
    t.bigint "study_id"
    t.string "plate_purpose_ids"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "report_filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["study_id"], name: "index_location_reports_on_study_id"
    t.index ["user_id"], name: "index_location_reports_on_user_id"
  end

  create_table "lot_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.string "template_class", null: false
    t.integer "target_purpose_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["target_purpose_id"], name: "fk_lot_types_to_plate_purposes"
  end

  create_table "lots", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "lot_number", null: false
    t.integer "lot_type_id", null: false
    t.integer "template_id", null: false
    t.string "template_type", null: false
    t.integer "user_id", null: false
    t.date "received_at", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["lot_number", "lot_type_id"], name: "index_lot_number_lot_type_id", unique: true
    t.index ["lot_type_id"], name: "fk_lots_to_lot_types"
  end

  create_table "maps", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "description", limit: 4
    t.integer "asset_size"
    t.integer "location_id"
    t.integer "row_order"
    t.integer "column_order"
    t.integer "asset_shape_id", default: 1, null: false
    t.index ["description", "asset_size"], name: "index_maps_on_description_and_asset_size"
    t.index ["description"], name: "index_maps_on_description"
  end

  create_table "messenger_creators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "template", null: false
    t.string "root", null: false
    t.integer "purpose_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "target_finder_class", default: "SelfFinder", null: false
    t.index ["purpose_id"], name: "fk_messenger_creators_to_plate_purposes"
  end

  create_table "messengers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "target_id"
    t.string "target_type"
    t.string "root", null: false
    t.string "template", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["target_id", "target_type"], name: "index_messengers_on_target_id_and_target_type"
  end

  create_table "order_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state_to_delete", limit: 20
    t.string "message_to_delete"
    t.integer "user_id"
    t.text "item_options"
    t.text "request_types"
    t.text "request_options"
    t.text "comments"
    t.integer "project_id"
    t.string "sti_type"
    t.string "template_name"
    t.integer "asset_group_id"
    t.string "asset_group_name"
    t.integer "submission_id"
    t.integer "pre_cap_group"
    t.integer "order_role_id"
    t.integer "product_id"
    t.index ["study_id"], name: "index_submissions_on_project_id"
    t.index ["submission_id"], name: "index_orders_on_submission_id"
  end

  create_table "pac_bio_library_tube_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "smrt_cells_available"
    t.string "prep_kit_barcode"
    t.string "binding_kit_barcode"
    t.string "movie_length"
    t.integer "pac_bio_library_tube_id"
    t.string "protocol"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["pac_bio_library_tube_id"], name: "index_pac_bio_library_tube_metadata_on_pac_bio_library_tube_id"
  end

  create_table "permissions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "role_name"
    t.string "name"
    t.string "permissable_type", limit: 50
    t.integer "permissable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pipeline_request_information_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "pipeline_id"
    t.integer "request_information_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pipelines", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.boolean "automated"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "next_pipeline_id"
    t.integer "previous_pipeline_id"
    t.boolean "group_by_parent"
    t.string "asset_type", limit: 50
    t.boolean "group_by_submission_to_delete"
    t.boolean "multiplexed"
    t.string "sti_type", limit: 50
    t.integer "sorter"
    t.boolean "paginate", default: false
    t.integer "max_size"
    t.boolean "summary", default: true
    t.boolean "group_by_study_to_delete", default: true
    t.boolean "externally_managed", default: false
    t.string "group_name"
    t.integer "control_request_type_id", null: false
    t.integer "min_size"
  end

  create_table "pipelines_request_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "pipeline_id", null: false
    t.integer "request_type_id", null: false
    t.index ["pipeline_id"], name: "fk_pipelines_request_types_to_pipelines"
    t.index ["request_type_id"], name: "fk_pipelines_request_types_to_request_types"
  end

  create_table "plate_conversions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "target_id", null: false
    t.integer "purpose_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "parent_id"
  end

  create_table "plate_creator_parent_purposes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "plate_creator_id", null: false
    t.integer "plate_purpose_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plate_creator_purposes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "plate_creator_id", null: false
    t.integer "plate_purpose_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "plate_creators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "valid_options"
    t.index ["name"], name: "index_plate_creators_on_name", unique: true
  end

  create_table "plate_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "plate_id"
    t.string "infinium_barcode"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "fluidigm_barcode", limit: 10
    t.decimal "dilution_factor", precision: 5, scale: 2, default: "1.0"
    t.index ["fluidigm_barcode"], name: "index_on_fluidigm_barcode", unique: true
    t.index ["plate_id"], name: "index_plate_metadata_on_plate_id"
  end

  create_table "plate_owners", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "plate_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "eventable_id", null: false
    t.string "eventable_type", null: false
  end

  create_table "plate_purpose_relationships", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.integer "transfer_request_type_id", null: false
  end

  create_table "plate_purposes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
    t.string "target_type", limit: 30
    t.boolean "stock_plate", default: false, null: false
    t.string "default_state", default: "pending"
    t.integer "barcode_printer_type_id"
    t.boolean "cherrypickable_target", default: true, null: false
    t.string "cherrypick_direction", default: "column", null: false
    t.string "cherrypick_filters"
    t.integer "size", default: 96
    t.integer "asset_shape_id", default: 1, null: false
    t.string "barcode_for_tecan", default: "ean13_barcode", null: false
    t.integer "source_purpose_id"
    t.integer "lifespan"
    t.index ["target_type"], name: "index_plate_purposes_on_target_type"
    t.index ["type"], name: "index_plate_purposes_on_type"
  end

  create_table "plate_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "maximum_volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plate_volumes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "barcode"
    t.string "uploaded_file_name"
    t.string "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["uploaded_file_name"], name: "index_plate_volumes_on_uploaded_file_name"
  end

  create_table "pooling_methods", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "pooling_behaviour", limit: 50, null: false
    t.text "pooling_options"
  end

  create_table "pre_capture_pool_pooled_requests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "pre_capture_pool_id", null: false
    t.integer "request_id", null: false
    t.index ["request_id"], name: "request_id_should_be_unique", unique: true
  end

  create_table "pre_capture_pools", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "primer_panels", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.integer "snp_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "programs"
  end

  create_table "product_catalogues", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.string "selection_behaviour", default: "SingleProduct", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_criteria", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "product_id", null: false
    t.string "stage", null: false
    t.string "behaviour", default: "Basic", null: false
    t.text "configuration"
    t.datetime "deprecated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version"
    t.index ["product_id", "stage", "version"], name: "index_product_criteria_on_product_id_and_stage_and_version", unique: true
  end

  create_table "product_lines", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
  end

  create_table "product_product_catalogues", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "product_id", null: false
    t.integer "product_catalogue_id", null: false
    t.string "selection_criterion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_catalogue_id"], name: "fk_product_product_catalogues_to_product_catalogues"
    t.index ["product_id"], name: "fk_product_product_catalogues_to_products"
  end

  create_table "products", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deprecated_at"
  end

  create_table "programs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "project_managers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "project_id"
    t.string "project_cost_code"
    t.string "funding_comments"
    t.string "collaborators"
    t.string "external_funding_source"
    t.string "sequencing_budget_cost_centre"
    t.string "project_funding_model"
    t.string "gt_committee_tracking_id"
    t.integer "project_manager_id", default: 1
    t.integer "budget_division_id", default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], name: "index_project_metadata_on_project_id"
  end

  create_table "projects", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.boolean "enforce_quotas", default: true
    t.boolean "approved", default: false
    t.string "state", limit: 20, default: "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["approved"], name: "index_projects_on_approved"
    t.index ["enforce_quotas"], name: "index_projects_on_enforce_quotas"
    t.index ["state"], name: "index_projects_on_state"
  end

  create_table "qc_decision_qcables", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "qc_decision_id", null: false
    t.integer "qcable_id", null: false
    t.string "decision", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_decisions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "lot_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_files", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "asset_id"
    t.integer "size"
    t.string "content_type"
    t.string "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["asset_id"], name: "fk_rails_31d6eeacb9"
  end

  create_table "qc_metric_requests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "qc_metric_id", null: false
    t.integer "request_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["qc_metric_id"], name: "fk_qc_metric_requests_to_qc_metrics"
    t.index ["request_id"], name: "fk_qc_metric_requests_to_requests"
  end

  create_table "qc_metrics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "qc_report_id", null: false
    t.integer "asset_id", null: false
    t.text "metrics"
    t.string "qc_decision", null: false
    t.boolean "proceed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "fk_qc_metrics_to_assets"
    t.index ["qc_report_id"], name: "fk_qc_metrics_to_qc_reports"
  end

  create_table "qc_reports", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "report_identifier", null: false
    t.integer "study_id", null: false
    t.integer "product_criteria_id", null: false
    t.boolean "exclude_existing", null: false
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "plate_purposes"
    t.index ["product_criteria_id"], name: "fk_qc_reports_to_product_criteria"
    t.index ["report_identifier"], name: "index_qc_reports_on_report_identifier", unique: true
    t.index ["study_id"], name: "fk_qc_reports_to_studies"
  end

  create_table "qc_results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "asset_id"
    t.string "key"
    t.string "value"
    t.string "units"
    t.float "cv", limit: 24
    t.string "assay_type"
    t.string "assay_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_qc_results_on_asset_id"
  end

  create_table "qcable_creators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "lot_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qcables", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "lot_id", null: false
    t.integer "asset_id", null: false
    t.string "state", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "qcable_creator_id", null: false
    t.index ["asset_id"], name: "index_asset_id"
    t.index ["lot_id"], name: "index_lot_id"
  end

  create_table "quotas_bkp", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "limit", default: 0
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "request_type_id"
    t.integer "preordered_count", default: 0
  end

  create_table "reference_genomes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_id", null: false
    t.string "event_name", null: false
    t.string "from_state"
    t.string "to_state"
    t.datetime "current_from", null: false
    t.datetime "current_to"
    t.index ["request_id", "current_to"], name: "index_request_events_on_request_id_and_current_to"
  end

  create_table "request_information_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "key", limit: 50
    t.string "label"
    t.integer "width"
    t.string "data_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "hide_in_inbox"
  end

  create_table "request_informations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_id"
    t.integer "request_information_type_id"
    t.string "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_id"
    t.string "name"
    t.string "tag"
    t.string "library_type"
    t.string "fragment_size_required_to"
    t.string "fragment_size_required_from"
    t.integer "read_length"
    t.integer "batch_id"
    t.integer "pipeline_id"
    t.string "pass"
    t.string "failure"
    t.string "library_creation_complete"
    t.string "sequencing_type"
    t.integer "insert_size"
    t.integer "bait_library_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "pre_capture_plex_level"
    t.float "gigabases_expected", limit: 24
    t.integer "target_purpose_id"
    t.boolean "customer_accepts_responsibility"
    t.integer "pcr_cycles"
    t.string "data_type"
    t.integer "primer_panel_id"
    t.index ["request_id"], name: "index_request_metadata_on_request_id"
  end

  create_table "request_quotas_bkp", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_id", null: false
    t.integer "quota_id", null: false
    t.index ["request_id"], name: "fk_request_quotas_to_requests"
  end

  create_table "request_type_plate_purposes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_type_id", null: false
    t.integer "plate_purpose_id", null: false
    t.index ["request_type_id", "plate_purpose_id"], name: "plate_purposes_are_unique_within_request_type", unique: true
  end

  create_table "request_type_validators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_type_id", null: false
    t.string "request_option", null: false
    t.text "valid_options", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "key", limit: 100
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "asset_type"
    t.integer "order"
    t.string "initial_state", limit: 20
    t.string "target_asset_type"
    t.boolean "multiples_allowed", default: false
    t.string "request_class_name"
    t.text "request_parameters"
    t.integer "morphology", default: 0
    t.boolean "for_multiplexing", default: false
    t.boolean "billable", default: false
    t.integer "product_line_id"
    t.boolean "deprecated", default: false, null: false
    t.boolean "no_target_asset", default: false, null: false
    t.integer "target_purpose_id"
    t.integer "pooling_method_id"
    t.integer "request_purpose"
    t.integer "billing_product_catalogue_id"
    t.index ["billing_product_catalogue_id"], name: "index_request_types_on_billing_product_catalogue_id"
  end

  create_table "request_types_extended_validators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "request_type_id", null: false
    t.integer "extended_validator_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["extended_validator_id"], name: "fk_request_types_extended_validators_to_extended_validators"
    t.index ["request_type_id"], name: "fk_request_types_extended_validators_to_request_types"
  end

  create_table "requests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "initial_study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "state", limit: 20, default: "pending"
    t.integer "sample_pool_id"
    t.integer "request_type_id"
    t.integer "item_id"
    t.integer "asset_id"
    t.integer "target_asset_id"
    t.integer "pipeline_id"
    t.integer "submission_id"
    t.boolean "charge"
    t.integer "initial_project_id"
    t.integer "priority", default: 0
    t.string "sti_type"
    t.integer "order_id"
    t.integer "request_purpose"
    t.integer "work_order_id"
    t.integer "billing_product_id"
    t.index ["asset_id"], name: "index_requests_on_asset_id"
    t.index ["billing_product_id"], name: "index_requests_on_billing_product_id"
    t.index ["initial_study_id", "request_type_id", "state"], name: "index_requests_on_project_id_and_request_type_id_and_state"
    t.index ["initial_study_id"], name: "index_request_on_project_id"
    t.index ["request_type_id", "state"], name: "request_type_id_state_index"
    t.index ["state", "request_type_id", "initial_study_id"], name: "request_project_index"
    t.index ["submission_id"], name: "index_requests_on_submission_id"
    t.index ["target_asset_id"], name: "index_requests_on_target_asset_id"
    t.index ["work_order_id"], name: "index_requests_on_work_order_id"
  end

  create_table "robot_properties", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "value"
    t.string "key", limit: 50
    t.integer "robot_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "robots", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "barcode"
    t.float "minimum_volume", limit: 24
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "authorizable_type", limit: 50
    t.integer "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["authorizable_id", "authorizable_type"], name: "index_roles_on_authorizable_id_and_authorizable_type"
    t.index ["authorizable_id"], name: "index_roles_on_authorizable_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "roles_users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "sample_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "sample_id"
    t.bigint "job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_sample_jobs_on_job_id"
    t.index ["sample_id"], name: "index_sample_jobs_on_sample_id"
  end

  create_table "sample_manifests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "study_id"
    t.integer "project_id"
    t.integer "supplier_id"
    t.integer "count"
    t.string "asset_type"
    t.text "last_errors"
    t.string "state"
    t.text "barcodes"
    t.integer "user_id"
    t.string "password"
    t.integer "purpose_id"
    t.index ["purpose_id"], name: "fk_rails_5627ab4aaa"
    t.index ["study_id"], name: "index_sample_manifests_on_study_id"
    t.index ["supplier_id"], name: "index_sample_manifests_on_supplier_id"
  end

  create_table "sample_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "sample_id"
    t.string "organism"
    t.string "gc_content"
    t.string "cohort"
    t.string "gender"
    t.string "country_of_origin"
    t.string "geographical_region"
    t.string "ethnicity"
    t.string "dna_source"
    t.string "volume"
    t.string "supplier_plate_id"
    t.string "mother"
    t.string "father"
    t.string "replicate"
    t.string "sample_public_name"
    t.string "sample_common_name"
    t.string "sample_strain_att"
    t.integer "sample_taxon_id"
    t.string "sample_ebi_accession_number"
    t.string "sample_sra_hold"
    t.string "sample_reference_genome_old"
    t.text "sample_description"
    t.string "sibling"
    t.boolean "is_resubmitted"
    t.string "date_of_sample_collection"
    t.string "date_of_sample_extraction"
    t.string "sample_extraction_method"
    t.string "sample_purified"
    t.string "purification_method"
    t.string "concentration"
    t.string "concentration_determined_by"
    t.string "sample_type"
    t.string "sample_storage_conditions"
    t.string "supplier_name"
    t.integer "reference_genome_id", default: 1
    t.string "genotype"
    t.string "phenotype"
    t.string "age"
    t.string "developmental_stage"
    t.string "cell_type"
    t.string "disease_state"
    t.string "compound"
    t.string "dose"
    t.string "immunoprecipitate"
    t.string "growth_condition"
    t.string "rnai"
    t.string "organism_part"
    t.string "time_point"
    t.string "disease"
    t.string "subject"
    t.string "treatment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "donor_id"
    t.index ["sample_ebi_accession_number"], name: "index_sample_metadata_on_sample_ebi_accession_number"
    t.index ["sample_id"], name: "index_sample_metadata_on_sample_id"
    t.index ["supplier_name"], name: "index_sample_metadata_on_supplier_name"
  end

  create_table "sample_registrars", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "study_id"
    t.integer "user_id"
    t.integer "sample_id"
    t.integer "sample_tube_id"
    t.integer "asset_group_id"
  end

  create_table "samples", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.boolean "new_name_format", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "sanger_sample_id"
    t.integer "sample_manifest_id"
    t.boolean "control"
    t.boolean "empty_supplier_sample_name", default: false
    t.boolean "updated_by_manifest", default: false
    t.boolean "consent_withdrawn", default: false, null: false
    t.integer "work_order_id"
    t.integer "container_id"
    t.index ["container_id"], name: "index_samples_on_container_id"
    t.index ["created_at"], name: "index_samples_on_created_at"
    t.index ["name"], name: "index_samples_on_name"
    t.index ["sample_manifest_id"], name: "index_samples_on_sample_manifest_id"
    t.index ["sanger_sample_id"], name: "index_samples_on_sanger_sample_id"
    t.index ["updated_at"], name: "index_samples_on_updated_at"
    t.index ["work_order_id"], name: "index_samples_on_work_order_id"
  end

  create_table "sanger_sample_ids", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
  end

  create_table "searches", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "target_model_name"
    t.text "default_parameters"
  end

  create_table "specific_tube_creation_purposes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "specific_tube_creation_id"
    t.integer "tube_purpose_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stamp_qcables", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "stamp_id", null: false
    t.integer "qcable_id", null: false
    t.string "bed", null: false
    t.integer "order", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["qcable_id"], name: "fk_stamp_qcables_to_qcables"
    t.index ["stamp_id"], name: "fk_stamp_qcables_to_stamps"
  end

  create_table "stamps", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "lot_id", null: false
    t.integer "user_id", null: false
    t.integer "robot_id", null: false
    t.string "tip_lot", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["lot_id"], name: "fk_stamps_to_lots"
    t.index ["robot_id"], name: "fk_stamps_to_robots"
    t.index ["user_id"], name: "fk_stamps_to_users"
  end

  create_table "state_changes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "target_id"
    t.string "contents", limit: 1024
    t.string "previous_state"
    t.string "target_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reason"
  end

  create_table "studies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.boolean "blocked", default: false
    t.string "state", limit: 20
    t.boolean "ethically_approved"
    t.boolean "enforce_data_release", default: true
    t.boolean "enforce_accessioning", default: true
    t.integer "reference_genome_id", default: 1
    t.index ["ethically_approved"], name: "index_studies_on_ethically_approved"
    t.index ["state"], name: "index_studies_on_state"
    t.index ["updated_at"], name: "index_studies_on_updated_at"
  end

  create_table "study_metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "study_id"
    t.string "old_sac_sponsor"
    t.text "study_description"
    t.string "contaminated_human_dna"
    t.string "study_project_id"
    t.text "study_abstract"
    t.string "study_study_title"
    t.string "study_ebi_accession_number"
    t.string "study_sra_hold"
    t.string "contains_human_dna"
    t.string "study_name_abbreviation"
    t.string "reference_genome_old"
    t.string "data_release_strategy"
    t.string "data_release_standard_agreement"
    t.string "data_release_timing"
    t.string "data_release_delay_reason"
    t.string "data_release_delay_other_comment"
    t.string "data_release_delay_period"
    t.string "data_release_delay_approval"
    t.string "data_release_delay_reason_comment"
    t.string "data_release_prevention_reason"
    t.string "data_release_prevention_approval"
    t.string "data_release_prevention_reason_comment"
    t.integer "snp_study_id"
    t.integer "snp_parent_study_id"
    t.boolean "bam", default: true
    t.integer "study_type_id"
    t.integer "data_release_study_type_id"
    t.integer "reference_genome_id", default: 1
    t.string "array_express_accession_number"
    t.text "dac_policy"
    t.string "ega_policy_accession_number"
    t.string "ega_dac_accession_number"
    t.string "commercially_available", default: "No"
    t.integer "faculty_sponsor_id"
    t.float "number_of_gigabases_per_sample", limit: 24
    t.string "hmdmc_approval_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remove_x_and_autosomes", default: "No", null: false
    t.string "dac_policy_title"
    t.boolean "separate_y_chromosome_data", default: false, null: false
    t.string "data_access_group"
    t.string "prelim_id"
    t.integer "program_id"
    t.string "s3_email_list"
    t.string "data_deletion_period"
    t.index ["faculty_sponsor_id"], name: "index_study_metadata_on_faculty_sponsor_id"
    t.index ["study_id"], name: "index_study_metadata_on_study_id"
  end

  create_table "study_relation_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "reversed_name"
  end

  create_table "study_relations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "study_id"
    t.integer "related_study_id"
    t.integer "study_relation_type_id"
  end

  create_table "study_reports", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "study_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "report_filename"
    t.string "content_type", default: "text/csv"
    t.index ["study_id"], name: "index_study_reports_on_study_id"
    t.index ["user_id"], name: "index_study_reports_on_user_id"
  end

  create_table "study_samples", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "study_id", null: false
    t.integer "sample_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["sample_id", "study_id"], name: "unique_samples_in_studies_idx", unique: true
    t.index ["sample_id"], name: "index_project_samples_on_sample_id"
    t.index ["study_id"], name: "index_project_samples_on_project_id"
  end

  create_table "study_samples_backup", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "id", default: 0, null: false
    t.integer "study_id"
    t.integer "sample_id"
  end

  create_table "study_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.boolean "valid_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "valid_for_creation", default: true, null: false
  end

  create_table "subclass_attributes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "value"
    t.integer "attributable_id"
    t.string "attributable_type", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["attributable_id", "name"], name: "index_subclass_attributes_on_attributable_id_and_name"
  end

  create_table "submission_templates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "submission_class_name"
    t.text "submission_parameters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "product_line_id"
    t.integer "superceded_by_id", default: -1, null: false
    t.datetime "superceded_at"
    t.integer "product_catalogue_id"
    t.index ["name", "superceded_by_id"], name: "name_and_superceded_by_unique_idx", unique: true
    t.index ["product_catalogue_id"], name: "fk_submission_templates_to_product_catalogues"
  end

  create_table "submissions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", limit: 20
    t.string "message"
    t.integer "user_id"
    t.text "request_types"
    t.text "request_options"
    t.string "name"
    t.integer "priority", limit: 1, default: 0, null: false
    t.integer "submission_template_id"
    t.index ["name"], name: "index_submissions_on_name"
    t.index ["state"], name: "index_submissions_on_state"
  end

  create_table "submitted_assets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "order_id"
    t.integer "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["asset_id"], name: "index_submitted_assets_on_asset_id"
  end

  create_table "suppliers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.string "address"
    t.string "contact_name"
    t.string "phone_number"
    t.string "fax"
    t.string "supplier_url"
    t.string "abbreviation"
    t.index ["name"], name: "index_suppliers_on_name"
  end

  create_table "tag2_layout_template_submissions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "submission_id", null: false
    t.integer "tag2_layout_template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "tag2_layout_template_id"], name: "tag2_layouts_used_once_per_submission", unique: true
    t.index ["tag2_layout_template_id"], name: "fk_tag2_layout_template_submissions_to_tag2_layout_templates"
  end

  create_table "tag2_layout_templates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tag2_layouts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "tag_id"
    t.integer "plate_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "source_id"
    t.text "target_well_locations"
  end

  create_table "tag_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "visible", default: true
    t.index ["name"], name: "tag_groups_unique_name", unique: true
  end

  create_table "tag_layout_templates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "direction_algorithm"
    t.integer "tag_group_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "walking_algorithm", default: "TagLayout::WalkWellsByPools"
    t.integer "tag2_group_id"
    t.index ["tag2_group_id"], name: "fk_rails_1c2c01e708"
  end

  create_table "tag_layouts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "direction_algorithm"
    t.integer "tag_group_id"
    t.integer "plate_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "substitutions", limit: 1525
    t.string "walking_algorithm", default: "TagLayout::WalkWellsByPools"
    t.integer "initial_tag", default: 0, null: false
    t.integer "tag2_group_id"
    t.index ["tag2_group_id"], name: "fk_rails_d221e7c041"
  end

  create_table "tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "oligo"
    t.integer "map_id"
    t.integer "tag_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["map_id"], name: "index_tags_on_map_id"
    t.index ["tag_group_id"], name: "index_tags_on_tag_group_id"
  end

  create_table "task_request_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "task_id"
    t.integer "request_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "order"
  end

  create_table "tasks", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "pipeline_workflow_id"
    t.integer "sorted"
    t.boolean "batched"
    t.string "location"
    t.boolean "interactive"
    t.boolean "per_item"
    t.string "sti_type", limit: 50
    t.boolean "lab_activity"
    t.integer "purpose_id"
    t.index ["name"], name: "index_tasks_on_name"
    t.index ["pipeline_workflow_id"], name: "index_tasks_on_pipeline_workflow_id"
    t.index ["sorted"], name: "index_tasks_on_sorted"
    t.index ["sti_type"], name: "index_tasks_on_sti_type"
  end

  create_table "transfer_request_collection_transfer_requests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "transfer_request_collection_id"
    t.integer "transfer_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transfer_request_collection_id"], name: "fk_rails_6b9c820b32"
    t.index ["transfer_request_id"], name: "fk_rails_67a3295574"
  end

  create_table "transfer_request_collections", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "fk_rails_e542f48171"
  end

  create_table "transfer_requests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", limit: 20, default: "pending"
    t.integer "asset_id"
    t.integer "target_asset_id"
    t.integer "submission_id"
    t.integer "order_id"
    t.index ["asset_id"], name: "index_requests_on_asset_id"
    t.index ["submission_id"], name: "index_requests_on_submission_id"
    t.index ["target_asset_id"], name: "index_requests_on_target_asset_id"
  end

  create_table "transfer_templates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "transfer_class_name"
    t.string "transfers", limit: 1024
  end

  create_table "transfers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "sti_type"
    t.integer "source_id"
    t.integer "destination_id"
    t.string "destination_type"
    t.text "transfers_hash"
    t.integer "bulk_transfer_id"
    t.integer "user_id"
    t.index ["source_id"], name: "source_id_idx"
  end

  create_table "tube_creation_children", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "tube_creation_id", null: false
    t.integer "tube_id", null: false
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "login"
    t.string "email"
    t.string "crypted_password", limit: 40
    t.string "salt", limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "api_key"
    t.string "first_name"
    t.string "last_name"
    t.boolean "pipeline_administrator"
    t.string "barcode"
    t.string "cookie"
    t.datetime "cookie_validated_at"
    t.string "encrypted_swipecard_code", limit: 40
    t.index ["barcode"], name: "index_users_on_barcode"
    t.index ["encrypted_swipecard_code"], name: "index_users_on_encrypted_swipecard_code"
    t.index ["login"], name: "index_users_on_login"
    t.index ["pipeline_administrator"], name: "index_users_on_pipeline_administrator"
  end

  create_table "uuids", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "resource_type", limit: 128, null: false
    t.integer "resource_id", null: false
    t.string "external_id", limit: 36, null: false
    t.index ["external_id"], name: "index_uuids_on_external_id"
    t.index ["resource_type", "resource_id"], name: "index_uuids_on_resource_type_and_resource_id"
  end

  create_table "volume_updates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "target_id"
    t.string "created_by"
    t.float "volume_change", limit: 24
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "well_attributes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "well_id"
    t.string "gel_pass", limit: 20
    t.float "concentration", limit: 24
    t.float "current_volume", limit: 24
    t.float "buffer_volume", limit: 24
    t.float "requested_volume", limit: 24
    t.float "picked_volume", limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "pico_pass", default: "ungraded", null: false
    t.integer "sequenom_count"
    t.string "study_id"
    t.string "gender_markers"
    t.string "gender"
    t.float "measured_volume", limit: 24
    t.float "initial_volume", limit: 24
    t.float "molarity", limit: 24
    t.float "rin", limit: 24
    t.float "robot_minimum_picking_volume", limit: 24
    t.index ["well_id"], name: "index_well_attributes_on_well_id"
  end

  create_table "well_links", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "target_well_id", null: false
    t.integer "source_well_id", null: false
    t.string "type", null: false
    t.index ["target_well_id"], name: "target_well_idx"
  end

  create_table "well_to_tube_transfers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "transfer_id", null: false
    t.integer "destination_id", null: false
    t.string "source"
  end

  create_table "work_completions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "target_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["target_id"], name: "fk_rails_f8fb9e95de"
    t.index ["user_id"], name: "fk_rails_204fc81a92"
  end

  create_table "work_completions_submissions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "work_completion_id", null: false
    t.integer "submission_id", null: false
    t.index ["submission_id"], name: "fk_rails_1ac4e93988"
    t.index ["work_completion_id"], name: "fk_rails_5ea64f1af2"
  end

  create_table "work_order_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_orders", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "work_order_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", null: false
    t.index ["work_order_type_id", "state"], name: "index_work_orders_on_work_order_type_id_and_state"
    t.index ["work_order_type_id"], name: "fk_rails_80841fcb4c"
  end

  create_table "workflow_samples", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.text "name"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "control", default: false
    t.integer "workflow_id"
    t.integer "submission_id"
    t.string "state", limit: 20
    t.integer "size", default: 1
    t.integer "version"
  end

  create_table "workflows", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "item_limit"
    t.text "locale"
    t.integer "pipeline_id"
    t.index ["pipeline_id"], name: "index_workflows_on_pipeline_id"
  end

  add_foreign_key "aliquots", "primer_panels"
  add_foreign_key "billing_items", "requests"
  add_foreign_key "billing_products", "billing_product_catalogues"
  add_foreign_key "qc_files", "assets"
  add_foreign_key "request_types", "billing_product_catalogues"
  add_foreign_key "requests", "billing_products"
  add_foreign_key "requests", "work_orders"
  add_foreign_key "sample_manifests", "plate_purposes", column: "purpose_id"
  add_foreign_key "tag_layout_templates", "tag_groups", column: "tag2_group_id"
  add_foreign_key "tag_layouts", "tag_groups", column: "tag2_group_id"
  add_foreign_key "transfer_request_collection_transfer_requests", "transfer_request_collections"
  add_foreign_key "transfer_request_collection_transfer_requests", "transfer_requests"
  add_foreign_key "transfer_request_collections", "users"
  add_foreign_key "work_completions", "assets", column: "target_id"
  add_foreign_key "work_completions", "users"
  add_foreign_key "work_completions_submissions", "submissions"
  add_foreign_key "work_completions_submissions", "work_completions"
  add_foreign_key "work_orders", "work_order_types"
end
