# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_01_14_135342) do
  create_table "aliquot_indices", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "aliquot_id", null: false
    t.integer "lane_id", null: false
    t.integer "aliquot_index", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["aliquot_id"], name: "index_aliquot_indices_on_aliquot_id", unique: true
    t.index ["lane_id", "aliquot_index"], name: "index_aliquot_indices_on_lane_id_and_aliquot_index", unique: true
  end

  create_table "aliquots", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "receptacle_id", null: false
    t.integer "study_id"
    t.integer "project_id"
    t.integer "library_id"
    t.integer "sample_id", null: false
    t.integer "tag_id"
    t.string "library_type"
    t.integer "insert_size_from"
    t.integer "insert_size_to"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "bait_library_id"
    t.integer "tag2_id", default: -1
    t.boolean "suboptimal", default: false, null: false
    t.bigint "primer_panel_id"
    t.integer "request_id"
    t.integer "tag_depth", default: 1
    t.index ["library_id"], name: "index_aliquots_on_library_id"
    t.index ["primer_panel_id"], name: "index_aliquots_on_primer_panel_id"
    t.index ["receptacle_id", "tag_id", "tag2_id", "tag_depth"], name: "aliquot_tag_tag2_and_tag_depth_are_unique_within_receptacle", unique: true
    t.index ["request_id"], name: "fk_rails_37734e1810"
    t.index ["sample_id"], name: "index_aliquots_on_sample_id"
    t.index ["study_id", "receptacle_id"], name: "index_aliquots_on_study_id_and_receptacle_id"
    t.index ["study_id"], name: "index_aliquots_on_study_id"
    t.index ["tag_id"], name: "tag_id_idx"
  end

  create_table "api_applications", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "key", null: false
    t.string "contact", null: false
    t.text "description", size: :medium
    t.string "privilege", null: false
    t.index ["key"], name: "index_api_applications_on_key"
  end

  create_table "asset_audits", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "message"
    t.string "key"
    t.string "created_by"
    t.integer "asset_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "witnessed_by"
    t.json "metadata"
    t.index ["asset_id"], name: "index_asset_audits_on_asset_id"
  end

  create_table "asset_barcodes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
  end

  create_table "asset_creation_parents", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "asset_creation_id"
    t.integer "parent_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "asset_creations", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "parent_id"
    t.integer "child_purpose_id"
    t.integer "child_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "type", null: false
  end

  create_table "asset_group_assets", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "asset_id"
    t.integer "asset_group_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["asset_group_id"], name: "index_asset_group_assets_on_asset_group_id"
    t.index ["asset_id"], name: "index_asset_group_assets_on_asset_id"
  end

  create_table "asset_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.integer "study_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "asset_links", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
    t.boolean "direct"
    t.integer "count"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ancestor_id", "descendant_id"], name: "index_asset_links_on_ancestor_id_and_descendant_id", unique: true
    t.index ["ancestor_id", "direct"], name: "index_asset_links_on_ancestor_id_and_direct"
    t.index ["descendant_id", "direct"], name: "index_asset_links_on_descendant_id_and_direct"
  end

  create_table "asset_shapes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.integer "horizontal_ratio", null: false
    t.integer "vertical_ratio", null: false
    t.string "description_strategy", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "assets_deprecated", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "sti_type", limit: 50
    t.string "barcode_bkp"
    t.string "qc_state", limit: 20
    t.boolean "resource"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "map_id"
    t.integer "size"
    t.boolean "closed", default: false
    t.string "public_name"
    t.boolean "archive"
    t.boolean "external_release"
    t.string "two_dimensional_barcode"
    t.integer "plate_purpose_id"
    t.decimal "volume", precision: 10, scale: 2
    t.integer "barcode_prefix_id_bkp"
    t.decimal "concentration", precision: 18, scale: 8
    t.integer "legacy_sample_id"
    t.integer "legacy_tag_id"
    t.integer "labware_type_id"
    t.index ["barcode_bkp"], name: "index_assets_deprecated_on_barcode_bkp"
    t.index ["barcode_prefix_id_bkp"], name: "index_assets_deprecated_on_barcode_prefix_id_bkp"
    t.index ["labware_type_id"], name: "fk_rails_512943c031"
    t.index ["sti_type", "plate_purpose_id"], name: "index_assets_on_plate_purpose_id_sti_type"
    t.index ["sti_type", "updated_at"], name: "index_assets_deprecated_on_sti_type_and_updated_at"
    t.index ["sti_type"], name: "index_assets_deprecated_on_sti_type"
    t.index ["updated_at"], name: "index_assets_deprecated_on_updated_at"
  end

  create_table "bait_libraries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "bait_library_supplier_id"
    t.string "name", null: false
    t.string "supplier_identifier"
    t.string "target_species", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "bait_library_type_id", null: false
    t.boolean "visible", default: true, null: false
    t.index ["bait_library_supplier_id", "name"], name: "bait_library_names_are_unique_within_a_supplier", unique: true
  end

  create_table "bait_library_layouts", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "plate_id", null: false
    t.string "layout", limit: 1024
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["plate_id"], name: "bait_libraries_are_laid_out_on_a_plate_once", unique: true
  end

  create_table "bait_library_suppliers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "visible", default: true, null: false
  end

  create_table "bait_library_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "visible", default: true, null: false
    t.integer "category"
    t.index ["name"], name: "index_bait_library_types_on_name", unique: true
  end

  create_table "barcode_prefixes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "prefix", limit: 3
    t.index ["prefix"], name: "index_barcode_prefixes_on_prefix"
  end

  create_table "barcode_printer_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "printer_type_id"
    t.string "type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "label_template_name"
    t.index ["name"], name: "index_barcode_printer_types_on_name"
    t.index ["type"], name: "index_barcode_printer_types_on_type"
  end

  create_table "barcode_printers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "barcode_printer_type_id"
    t.integer "print_service", default: 0
    t.integer "printer_type", default: 1
  end

  create_table "barcodes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.string "barcode", null: false
    t.integer "format", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["asset_id"], name: "index_barcodes_on_asset_id"
    t.index ["barcode"], name: "index_barcodes_on_barcode"
  end

  create_table "batch_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "batch_id", null: false
    t.integer "request_id", null: false
    t.integer "position"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["batch_id"], name: "index_batch_requests_on_batch_id"
    t.index ["request_id"], name: "request_id", unique: true
  end

  create_table "batches", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "item_limit"
    t.datetime "created_at", precision: nil
    t.integer "user_id"
    t.datetime "updated_at", precision: nil
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

  create_table "bkp_lab_events", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "id", default: 0, null: false
    t.text "description", size: :medium
    t.text "descriptors", size: :medium
    t.text "descriptor_fields", size: :medium
    t.integer "eventful_id"
    t.string "eventful_type", limit: 50
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "filename"
    t.binary "data"
    t.text "message", size: :medium
    t.integer "user_id"
    t.integer "batch_id"
  end

  create_table "broadcast_events", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "sti_type"
    t.string "seed_type"
    t.integer "seed_id"
    t.integer "user_id"
    t.text "properties", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "budget_divisions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "bulk_transfers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
  end

  create_table "comments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.string "commentable_type", limit: 50
    t.integer "user_id"
    t.text "description", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "commentable_id", null: false
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
  end

  create_table "container_associations_deprecated", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "container_id", null: false
    t.integer "content_id", null: false
    t.index ["container_id"], name: "index_container_associations_deprecated_on_container_id"
    t.index ["content_id"], name: "container_association_content_is_unique", unique: true
  end

  create_table "controls", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "item_id"
    t.integer "pipeline_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "custom_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.integer "custom_metadatum_collection_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["custom_metadatum_collection_id"], name: "index_custom_metadata_on_custom_metadatum_collection_id"
    t.index ["key", "value"], name: "index_custom_metadata_on_key_and_value"
  end

  create_table "custom_metadatum_collections", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["asset_id"], name: "index_custom_metadatum_collections_on_asset_id"
  end

  create_table "custom_texts", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "identifier"
    t.integer "differential"
    t.string "content_type"
    t.text "content", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "data_release_study_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "for_array_express", default: false
    t.boolean "is_default", default: false
    t.boolean "is_assay_type", default: false
  end

  create_table "db_files", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.binary "data", size: :long
    t.integer "owner_id"
    t.string "owner_type", limit: 25, default: "Document", null: false
    t.string "owner_type_extended"
    t.index ["owner_type", "owner_id"], name: "index_db_files_on_owner_type_and_owner_id"
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler", size: :medium
    t.text "last_error", size: :medium
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "queue"
  end

  create_table "descriptors", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.text "selection", size: :medium
    t.integer "task_id"
    t.string "kind"
    t.boolean "required"
    t.integer "sorter"
    t.string "key", limit: 50
    t.index ["task_id"], name: "index_descriptors_on_task_id"
  end

  create_table "documents", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
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

  create_table "equipment", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "equipment_type"
    t.string "prefix", limit: 2, null: false
    t.string "ean13_barcode", limit: 13
  end

  create_table "events", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "eventful_id"
    t.string "eventful_type", limit: 50
    t.string "message"
    t.string "family"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "identifier"
    t.string "location"
    t.boolean "actioned"
    t.text "content", size: :medium
    t.string "created_by"
    t.string "of_interest_to"
    t.string "descriptor_key", limit: 50
    t.string "type", default: "Event"
    t.index ["eventful_id"], name: "index_events_on_eventful_id"
    t.index ["eventful_type"], name: "index_events_on_eventful_type"
  end

  create_table "extended_validators", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "behaviour", null: false
    t.text "options", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "external_properties", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "propertied_id"
    t.string "propertied_type", limit: 50
    t.string "key", limit: 50
    t.string "value"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["propertied_id", "propertied_type", "key"], name: "ep_pi_pt_key"
  end

  create_table "extraction_attributes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "target_id"
    t.string "created_by"
    t.text "attributes_update", size: :long
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "faculty_sponsors", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "failures", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "failable_id"
    t.string "failable_type", limit: 50
    t.text "reason", size: :medium
    t.boolean "notify_remote"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "comment", size: :medium
    t.index ["failable_id"], name: "index_failures_on_failable_id"
  end

  create_table "flipper_features", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "flowcell_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_flowcell_types_on_name", unique: true
  end

  create_table "flowcell_types_request_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "flowcell_type_id", null: false
    t.integer "request_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flowcell_type_id"], name: "index_flowcell_types_request_types_on_flowcell_type_id"
    t.index ["request_type_id"], name: "index_flowcell_types_request_types_on_request_type_id"
  end

  create_table "identifiers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
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

  create_table "implements", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "barcode"
    t.string "equipment_type"
  end

  create_table "isndc_countries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.integer "sort_priority", default: 0, null: false
    t.integer "validation_state", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_isndc_countries_on_name", unique: true
    t.index ["sort_priority"], name: "index_isndc_countries_on_sort_priority"
    t.index ["validation_state"], name: "index_isndc_countries_on_validation_state"
  end

  create_table "items", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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

  create_table "lab_events", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "description"
    t.text "descriptors", size: :medium
    t.integer "eventful_id"
    t.string "eventful_type", limit: 50
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "message", size: :medium
    t.integer "user_id"
    t.integer "batch_id"
    t.index ["batch_id"], name: "index_lab_events_on_batch_id"
    t.index ["description", "eventful_type"], name: "index_lab_events_find_flowcell", length: { description: 20 }
    t.index ["eventful_id"], name: "index_lab_events_on_eventful_id"
    t.index ["eventful_type"], name: "index_lab_events_on_eventful_type"
  end

  create_table "labware", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "sti_type", limit: 50, default: "Labware", null: false
    t.integer "size"
    t.string "public_name"
    t.string "two_dimensional_barcode"
    t.integer "plate_purpose_id"
    t.integer "labware_type_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "retention_instruction"
    t.index ["labware_type_id"], name: "fk_rails_32b35f8bf9"
    t.index ["plate_purpose_id"], name: "fk_rails_745455e964"
    t.index ["sti_type", "plate_purpose_id"], name: "index_labware_on_sti_type_and_plate_purpose_id"
    t.index ["sti_type", "updated_at"], name: "index_labware_on_sti_type_and_updated_at"
    t.index ["updated_at"], name: "index_labware_on_updated_at"
  end

  create_table "lane_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "lane_id"
    t.string "release_reason"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "library_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["name"], name: "index_library_types_on_name", unique: true
  end

  create_table "library_types_request_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "request_type_id", null: false
    t.integer "library_type_id", null: false
    t.boolean "is_default", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["library_type_id"], name: "fk_library_types_request_types_to_library_types"
    t.index ["request_type_id"], name: "fk_library_types_request_types_to_request_types"
  end

  create_table "location_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "report_type", null: false
    t.string "location_barcode"
    t.text "barcodes", size: :medium
    t.string "faculty_sponsor_ids"
    t.bigint "study_id"
    t.string "plate_purpose_ids"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.string "report_filename"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["study_id"], name: "index_location_reports_on_study_id"
    t.index ["user_id"], name: "index_location_reports_on_user_id"
  end

  create_table "lot_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "template_class", null: false
    t.integer "target_purpose_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["target_purpose_id"], name: "fk_lot_types_to_plate_purposes"
  end

  create_table "lots", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "lot_number", null: false
    t.integer "lot_type_id", null: false
    t.integer "template_id", null: false
    t.string "template_type", null: false
    t.integer "user_id", null: false
    t.date "received_at", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["lot_number", "lot_type_id"], name: "index_lot_number_lot_type_id", unique: true
    t.index ["lot_type_id"], name: "fk_lots_to_lot_types"
  end

  create_table "maps", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "description", limit: 4
    t.integer "asset_size"
    t.integer "location_id"
    t.integer "row_order"
    t.integer "column_order"
    t.integer "asset_shape_id", default: 1, null: false
    t.index ["description", "asset_size"], name: "index_maps_on_description_and_asset_size"
    t.index ["description"], name: "index_maps_on_description"
  end

  create_table "messenger_creators", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "template", null: false
    t.string "root", null: false
    t.integer "purpose_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "target_finder_class", default: "SelfFinder", null: false
    t.index ["purpose_id"], name: "fk_messenger_creators_to_plate_purposes"
  end

  create_table "messengers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "target_id"
    t.string "target_type"
    t.string "root", null: false
    t.string "template", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["target_id", "target_type"], name: "index_messengers_on_target_id_and_target_type"
  end

  create_table "order_roles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "role"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "orders", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "study_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "state_to_delete", limit: 20
    t.string "message_to_delete"
    t.integer "user_id"
    t.text "item_options", size: :medium
    t.text "request_types", size: :medium
    t.text "request_options", size: :medium
    t.text "comments", size: :medium
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

  create_table "pac_bio_library_tube_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "smrt_cells_available"
    t.string "prep_kit_barcode"
    t.string "binding_kit_barcode"
    t.string "movie_length"
    t.integer "pac_bio_library_tube_id"
    t.string "protocol"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["pac_bio_library_tube_id"], name: "index_pac_bio_library_tube_metadata_on_pac_bio_library_tube_id"
  end

  create_table "permissions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "role_name"
    t.string "name"
    t.string "permissable_type", limit: 50
    t.integer "permissable_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "pick_lists", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "state", default: 0, null: false
    t.integer "submission_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["submission_id"], name: "index_pick_lists_on_submission_id"
  end

  create_table "pipeline_request_information_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "pipeline_id"
    t.integer "request_information_type_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "pipelines", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "multiplexed"
    t.string "sti_type", limit: 50
    t.integer "sorter"
    t.integer "max_size"
    t.boolean "summary", default: true
    t.boolean "externally_managed", default: false
    t.string "group_name"
    t.integer "control_request_type_id", null: false
    t.integer "min_size"
    t.string "validator_class_name"
  end

  create_table "pipelines_request_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "pipeline_id", null: false
    t.integer "request_type_id", null: false
    t.index ["pipeline_id"], name: "fk_pipelines_request_types_to_pipelines"
    t.index ["request_type_id"], name: "fk_pipelines_request_types_to_request_types"
  end

  create_table "plate_conversions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "target_id", null: false
    t.integer "purpose_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "parent_id"
  end

  create_table "plate_creator_parent_purposes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "plate_creator_id", null: false
    t.integer "plate_purpose_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "plate_creator_purposes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "plate_creator_id", null: false
    t.integer "plate_purpose_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "plate_creators", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "valid_options", size: :medium
    t.index ["name"], name: "index_plate_creators_on_name", unique: true
  end

  create_table "plate_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "plate_id"
    t.string "infinium_barcode_bkp"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "fluidigm_barcode_bkp", limit: 10
    t.decimal "dilution_factor", precision: 5, scale: 2, default: "1.0"
    t.index ["fluidigm_barcode_bkp"], name: "index_on_fluidigm_barcode", unique: true
    t.index ["plate_id"], name: "index_plate_metadata_on_plate_id"
  end

  create_table "plate_owners", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "plate_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "eventable_id", null: false
    t.string "eventable_type", null: false
  end

  create_table "plate_purpose_relationships", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "parent_id"
    t.integer "child_id"
  end

  create_table "plate_purposes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "type"
    t.string "target_type", limit: 30
    t.boolean "stock_plate", default: false, null: false
    t.string "default_state", default: "pending"
    t.integer "barcode_printer_type_id"
    t.boolean "cherrypickable_target", default: true, null: false
    t.string "cherrypick_direction", default: "column", null: false
    t.integer "size", default: 96
    t.integer "asset_shape_id", default: 1, null: false
    t.integer "source_purpose_id"
    t.integer "lifespan"
    t.integer "barcode_prefix_id"
    t.index ["barcode_prefix_id"], name: "fk_rails_763bed2756"
    t.index ["target_type"], name: "index_plate_purposes_on_target_type"
    t.index ["type"], name: "index_plate_purposes_on_type"
  end

  create_table "plate_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "maximum_volume"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "plate_volumes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "barcode"
    t.string "uploaded_file_name"
    t.string "state"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["uploaded_file_name"], name: "index_plate_volumes_on_uploaded_file_name"
  end

  create_table "poly_metadata", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.string "metadatable_type", null: false
    t.bigint "metadatable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadatable_type", "metadatable_id"], name: "index_poly_metadata_on_metadatable_type_and_metadatable_id"
  end

  create_table "pooling_methods", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "pooling_behaviour", limit: 50, null: false
    t.text "pooling_options", size: :medium
  end

  create_table "pre_capture_pool_pooled_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "pre_capture_pool_id", null: false
    t.integer "request_id", null: false
    t.index ["request_id"], name: "request_id_should_be_unique", unique: true
  end

  create_table "pre_capture_pools", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "primer_panels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.integer "snp_count", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "programs", size: :medium
  end

  create_table "product_catalogues", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "selection_behaviour", default: "SingleProduct", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "product_criteria", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "stage", null: false
    t.string "behaviour", default: "Basic", null: false
    t.text "configuration", size: :medium
    t.datetime "deprecated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "version"
    t.index ["product_id", "stage", "version"], name: "index_product_criteria_on_product_id_and_stage_and_version", unique: true
  end

  create_table "product_lines", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "product_product_catalogues", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "product_catalogue_id", null: false
    t.string "selection_criterion"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["product_catalogue_id"], name: "fk_product_product_catalogues_to_product_catalogues"
    t.index ["product_id"], name: "fk_product_product_catalogues_to_products"
  end

  create_table "products", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deprecated_at", precision: nil
  end

  create_table "programs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "project_managers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "project_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
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
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["project_id"], name: "index_project_metadata_on_project_id"
  end

  create_table "projects", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.boolean "enforce_quotas", default: true
    t.boolean "approved", default: false
    t.string "state", limit: 20, default: "pending"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["approved"], name: "index_projects_on_approved"
    t.index ["enforce_quotas"], name: "index_projects_on_enforce_quotas"
    t.index ["state"], name: "index_projects_on_state"
  end

  create_table "qc_assays", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "lot_number"
  end

  create_table "qc_decision_qcables", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "qc_decision_id", null: false
    t.integer "qcable_id", null: false
    t.string "decision", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "qc_decisions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "lot_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "qc_files", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "asset_id"
    t.integer "size"
    t.string "content_type"
    t.string "filename"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["asset_id"], name: "fk_rails_31d6eeacb9"
  end

  create_table "qc_metric_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "qc_metric_id", null: false
    t.integer "request_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["qc_metric_id"], name: "fk_qc_metric_requests_to_qc_metrics"
    t.index ["request_id"], name: "fk_qc_metric_requests_to_requests"
  end

  create_table "qc_metrics", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "qc_report_id", null: false
    t.integer "asset_id", null: false
    t.text "metrics", size: :medium
    t.string "qc_decision", null: false
    t.boolean "proceed"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["asset_id"], name: "fk_qc_metrics_to_assets"
    t.index ["qc_report_id"], name: "fk_qc_metrics_to_qc_reports"
  end

  create_table "qc_reports", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "report_identifier", null: false
    t.integer "study_id", null: false
    t.integer "product_criteria_id", null: false
    t.boolean "exclude_existing", null: false
    t.string "state"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "plate_purposes", size: :medium
    t.index ["product_criteria_id"], name: "fk_qc_reports_to_product_criteria"
    t.index ["report_identifier"], name: "index_qc_reports_on_report_identifier", unique: true
    t.index ["study_id"], name: "fk_qc_reports_to_studies"
  end

  create_table "qc_results", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "asset_id"
    t.string "key"
    t.string "value"
    t.string "units"
    t.float "cv"
    t.string "assay_type"
    t.string "assay_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "qc_assay_id"
    t.index ["asset_id"], name: "index_qc_results_on_asset_id"
    t.index ["qc_assay_id"], name: "index_qc_results_on_qc_assay_id"
  end

  create_table "qcable_creators", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "lot_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["user_id"], name: "fk_qcable_creators_to_users"
  end

  create_table "qcables", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "lot_id", null: false
    t.integer "asset_id", null: false
    t.string "state", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "qcable_creator_id", null: false
    t.index ["asset_id"], name: "index_asset_id"
    t.index ["lot_id"], name: "index_lot_id"
  end

  create_table "racked_tubes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "tube_rack_id"
    t.bigint "tube_id"
    t.string "coordinate"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tube_id"], name: "index_racked_tubes_on_tube_id"
    t.index ["tube_rack_id"], name: "index_racked_tubes_on_tube_rack_id"
  end

  create_table "receptacles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "sti_type", limit: 50, default: "Receptacle", null: false
    t.string "qc_state", limit: 20
    t.boolean "resource"
    t.integer "map_id"
    t.boolean "closed", default: false
    t.boolean "external_release"
    t.decimal "volume", precision: 10, scale: 2
    t.decimal "concentration", precision: 18, scale: 8
    t.integer "labware_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "pcr_cycles"
    t.boolean "submit_for_sequencing"
    t.integer "sub_pool"
    t.integer "coverage"
    t.decimal "diluent_volume", precision: 10, scale: 2
    t.index ["labware_id"], name: "fk_rails_2201f76983"
    t.index ["sti_type", "updated_at"], name: "index_receptacles_on_sti_type_and_updated_at"
    t.index ["updated_at"], name: "index_receptacles_on_updated_at"
  end

  create_table "reference_genomes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "request_events", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "request_id", null: false
    t.string "event_name", null: false
    t.string "from_state"
    t.string "to_state"
    t.datetime "current_from", precision: nil, null: false
    t.datetime "current_to", precision: nil
    t.index ["request_id", "current_to"], name: "index_request_events_on_request_id_and_current_to"
  end

  create_table "request_information_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "key", limit: 50
    t.string "label"
    t.integer "width"
    t.string "data_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "hide_in_inbox"
  end

  create_table "request_informations", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "request_id"
    t.integer "request_information_type_id"
    t.string "value"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "request_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
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
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "pre_capture_plex_level"
    t.float "gigabases_expected"
    t.integer "target_purpose_id"
    t.boolean "customer_accepts_responsibility"
    t.integer "pcr_cycles"
    t.string "data_type"
    t.integer "primer_panel_id"
    t.string "requested_flowcell_type"
    t.integer "number_of_pools"
    t.integer "cells_per_chip_well"
    t.index ["request_id"], name: "index_request_metadata_on_request_id"
  end

  create_table "request_type_plate_purposes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "request_type_id", null: false
    t.integer "plate_purpose_id", null: false
    t.index ["request_type_id", "plate_purpose_id"], name: "plate_purposes_are_unique_within_request_type", unique: true
  end

  create_table "request_type_validators", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "request_type_id", null: false
    t.string "request_option", null: false
    t.text "valid_options", size: :medium, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "key"
    t.index ["key"], name: "index_request_type_validators_on_key", unique: true
  end

  create_table "request_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "key", limit: 100
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "asset_type"
    t.integer "order"
    t.string "initial_state", limit: 20
    t.string "target_asset_type"
    t.boolean "multiples_allowed", default: false
    t.string "request_class_name"
    t.text "request_parameters", size: :medium
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

  create_table "request_types_extended_validators", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "request_type_id", null: false
    t.integer "extended_validator_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["extended_validator_id"], name: "fk_request_types_extended_validators_to_extended_validators"
    t.index ["request_type_id"], name: "fk_request_types_extended_validators_to_request_types"
  end

  create_table "requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "initial_study_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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

  create_table "robot_properties", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "key", limit: 50
    t.integer "robot_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "robots", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "barcode"
  end

  create_table "roles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "authorizable_type", limit: 50
    t.integer "authorizable_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["authorizable_id", "authorizable_type"], name: "index_roles_on_authorizable_id_and_authorizable_type"
    t.index ["authorizable_id"], name: "index_roles_on_authorizable_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "roles_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "sample_compounds_components", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "compound_sample_id", null: false
    t.integer "component_sample_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sample_manifest_assets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.bigint "sample_manifest_id"
    t.bigint "asset_id"
    t.string "sanger_sample_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["asset_id"], name: "index_sample_manifest_assets_on_asset_id"
    t.index ["sample_manifest_id"], name: "index_sample_manifest_assets_on_sample_manifest_id"
    t.index ["sanger_sample_id"], name: "index_sample_manifest_assets_on_sanger_sample_id"
  end

  create_table "sample_manifests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "study_id"
    t.integer "project_id"
    t.integer "supplier_id"
    t.integer "count"
    t.string "asset_type"
    t.text "last_errors", size: :medium
    t.string "state"
    t.text "barcodes", size: :medium
    t.integer "user_id"
    t.string "password"
    t.integer "purpose_id"
    t.integer "tube_rack_purpose_id"
    t.integer "rows_per_well"
    t.index ["purpose_id"], name: "fk_rails_5627ab4aaa"
    t.index ["study_id"], name: "index_sample_manifests_on_study_id"
    t.index ["supplier_id"], name: "index_sample_manifests_on_supplier_id"
  end

  create_table "sample_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
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
    t.string "mother"
    t.string "father"
    t.string "replicate"
    t.string "sample_public_name"
    t.string "sample_common_name"
    t.string "sample_strain_att"
    t.integer "sample_taxon_id"
    t.string "sample_ebi_accession_number"
    t.string "sample_sra_hold"
    t.text "sample_description", size: :medium
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
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "donor_id"
    t.integer "genome_size"
    t.datetime "date_of_consent_withdrawn", precision: nil
    t.integer "user_id_of_consent_withdrawn"
    t.boolean "consent_withdrawn", default: false, null: false
    t.string "collected_by", comment: "Name of persons or institute who collected the specimen"
    t.string "huMFre_code", limit: 16
    t.index ["sample_ebi_accession_number"], name: "index_sample_metadata_on_sample_ebi_accession_number"
    t.index ["sample_id"], name: "index_sample_metadata_on_sample_id"
    t.index ["supplier_name"], name: "index_sample_metadata_on_supplier_name"
  end

  create_table "sample_registrars", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "study_id"
    t.integer "user_id"
    t.integer "sample_id"
    t.integer "sample_tube_id"
    t.integer "asset_group_id"
  end

  create_table "samples", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.boolean "new_name_format", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "sanger_sample_id"
    t.integer "sample_manifest_id"
    t.boolean "control"
    t.boolean "empty_supplier_sample_name", default: false
    t.boolean "updated_by_manifest", default: false
    t.integer "work_order_id"
    t.integer "container_id"
    t.integer "control_type"
    t.integer "priority", default: 0
    t.index ["created_at"], name: "index_samples_on_created_at"
    t.index ["name"], name: "index_samples_on_name"
    t.index ["sample_manifest_id"], name: "index_samples_on_sample_manifest_id"
    t.index ["sanger_sample_id"], name: "index_samples_on_sanger_sample_id"
    t.index ["updated_at"], name: "index_samples_on_updated_at"
  end

  create_table "sanger_sample_ids", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
  end

  create_table "searches", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "target_model_name"
    t.text "default_parameters", size: :medium
  end

  create_table "specific_tube_creation_purposes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "specific_tube_creation_id"
    t.integer "tube_purpose_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "stamp_qcables", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "stamp_id", null: false
    t.integer "qcable_id", null: false
    t.string "bed", null: false
    t.integer "order", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["qcable_id"], name: "fk_stamp_qcables_to_qcables"
    t.index ["stamp_id"], name: "fk_stamp_qcables_to_stamps"
  end

  create_table "stamps", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "lot_id", null: false
    t.integer "user_id", null: false
    t.integer "robot_id", null: false
    t.string "tip_lot", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["lot_id"], name: "fk_stamps_to_lots"
    t.index ["robot_id"], name: "fk_stamps_to_robots"
    t.index ["user_id"], name: "fk_stamps_to_users"
  end

  create_table "state_changes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.integer "target_id"
    t.string "contents", limit: 4096
    t.string "previous_state"
    t.string "target_state"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "reason"
  end

  create_table "studies", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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

  create_table "study_metadata", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "study_id"
    t.string "old_sac_sponsor"
    t.text "study_description", size: :medium
    t.string "contaminated_human_dna"
    t.string "study_project_id"
    t.text "study_abstract", size: :medium
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
    t.text "dac_policy", size: :medium
    t.string "ega_policy_accession_number"
    t.string "ega_dac_accession_number"
    t.string "commercially_available", default: "No"
    t.integer "faculty_sponsor_id"
    t.float "number_of_gigabases_per_sample"
    t.string "hmdmc_approval_number"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "remove_x_and_autosomes", default: "No", null: false
    t.string "dac_policy_title"
    t.boolean "separate_y_chromosome_data", default: false, null: false
    t.string "data_access_group"
    t.string "prelim_id"
    t.integer "program_id"
    t.string "s3_email_list"
    t.string "data_deletion_period"
    t.string "contaminated_human_data_access_group"
    t.string "ebi_library_strategy"
    t.string "ebi_library_source"
    t.string "ebi_library_selection"
    t.string "data_release_prevention_other_comment"
    t.index ["faculty_sponsor_id"], name: "index_study_metadata_on_faculty_sponsor_id"
    t.index ["study_id"], name: "index_study_metadata_on_study_id"
  end

  create_table "study_reports", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "study_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "report_filename"
    t.string "content_type", default: "text/csv"
    t.index ["study_id"], name: "index_study_reports_on_study_id"
    t.index ["user_id"], name: "index_study_reports_on_user_id"
  end

  create_table "study_samples", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "study_id", null: false
    t.integer "sample_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["sample_id", "study_id"], name: "unique_samples_in_studies_idx", unique: true
    t.index ["sample_id"], name: "index_project_samples_on_sample_id"
    t.index ["study_id"], name: "index_project_samples_on_project_id"
  end

  create_table "study_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.boolean "valid_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "valid_for_creation", default: true, null: false
  end

  create_table "subclass_attributes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.integer "attributable_id"
    t.string "attributable_type", limit: 50
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["attributable_id", "name"], name: "index_subclass_attributes_on_attributable_id_and_name"
  end

  create_table "submission_templates", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "submission_class_name"
    t.text "submission_parameters", size: :medium
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "product_line_id"
    t.integer "superceded_by_id", default: -1, null: false
    t.datetime "superceded_at", precision: nil
    t.integer "product_catalogue_id"
    t.index ["name", "superceded_by_id"], name: "name_and_superceded_by_unique_idx", unique: true
    t.index ["product_catalogue_id"], name: "fk_submission_templates_to_product_catalogues"
  end

  create_table "submissions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "state", limit: 20
    t.string "message"
    t.integer "user_id"
    t.text "request_types", size: :medium
    t.text "request_options", size: :medium
    t.string "name"
    t.integer "priority", limit: 1, default: 0, null: false
    t.index ["name"], name: "index_submissions_on_name"
    t.index ["state"], name: "index_submissions_on_state"
  end

  create_table "submitted_assets", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "order_id"
    t.integer "asset_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["asset_id"], name: "index_submitted_assets_on_asset_id"
  end

  create_table "suppliers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "email"
    t.string "address"
    t.string "contact_name"
    t.string "phone_number"
    t.string "fax"
    t.string "supplier_url"
    t.string "abbreviation"
    t.index ["name"], name: "index_suppliers_on_name"
  end

  create_table "tag2_layout_template_submissions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "submission_id", null: false
    t.integer "tag2_layout_template_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["submission_id", "tag2_layout_template_id"], name: "tag2_layouts_used_once_per_submission", unique: true
    t.index ["tag2_layout_template_id"], name: "fk_tag2_layout_template_submissions_to_tag2_layout_templates"
  end

  create_table "tag2_layout_templates", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "tag2_layouts", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "plate_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "source_id"
    t.text "target_well_locations", size: :medium
  end

  create_table "tag_group_adapter_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "tag_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "visible", default: true
    t.bigint "adapter_type_id"
    t.index ["adapter_type_id"], name: "index_tag_groups_on_adapter_type_id"
    t.index ["name"], name: "tag_groups_unique_name", unique: true
  end

  create_table "tag_layout_template_submissions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "submission_id", null: false
    t.integer "tag_layout_template_id", null: false
    t.boolean "enforce_uniqueness"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["submission_id", "tag_layout_template_id", "enforce_uniqueness"], name: "tag_layout_uniqueness", unique: true
    t.index ["submission_id"], name: "index_tag_layout_template_submissions_on_submission_id"
    t.index ["tag_layout_template_id"], name: "index_tag_layout_template_submissions_on_tag_layout_template_id"
  end

  create_table "tag_layout_templates", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "direction_algorithm"
    t.integer "tag_group_id"
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "walking_algorithm", default: "TagLayout::WalkWellsByPools"
    t.integer "tag2_group_id"
    t.boolean "enabled", default: true, null: false
    t.index ["tag2_group_id"], name: "fk_rails_1c2c01e708"
  end

  create_table "tag_layouts", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "direction_algorithm"
    t.integer "tag_group_id"
    t.integer "plate_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "substitutions", limit: 1525
    t.string "walking_algorithm", default: "TagLayout::WalkWellsByPools"
    t.integer "initial_tag", default: 0, null: false
    t.integer "tag2_group_id"
    t.index ["tag2_group_id"], name: "fk_rails_d221e7c041"
  end

  create_table "tag_sets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "tag_group_id", null: false
    t.integer "tag2_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag2_group_id"], name: "index_tag_sets_on_tag2_group_id"
    t.index ["tag_group_id"], name: "index_tag_sets_on_tag_group_id"
  end

  create_table "tags", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "oligo"
    t.integer "map_id"
    t.integer "tag_group_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["map_id"], name: "index_tags_on_map_id"
    t.index ["tag_group_id"], name: "index_tags_on_tag_group_id"
  end

  create_table "tasks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
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

  create_table "transfer_request_collection_transfer_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "transfer_request_collection_id"
    t.integer "transfer_request_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["transfer_request_collection_id"], name: "fk_rails_6b9c820b32"
    t.index ["transfer_request_id"], name: "fk_rails_67a3295574"
  end

  create_table "transfer_request_collections", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "fk_rails_e542f48171"
  end

  create_table "transfer_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "state", limit: 20, default: "pending"
    t.integer "asset_id"
    t.integer "target_asset_id"
    t.integer "submission_id"
    t.integer "order_id"
    t.float "volume"
    t.index ["asset_id"], name: "index_requests_on_asset_id"
    t.index ["submission_id"], name: "index_requests_on_submission_id"
    t.index ["target_asset_id"], name: "index_requests_on_target_asset_id"
  end

  create_table "transfer_templates", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "name"
    t.string "transfer_class_name"
    t.string "transfers", limit: 10240
  end

  create_table "transfers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "sti_type"
    t.integer "source_id"
    t.integer "destination_id"
    t.text "transfers_hash", size: :medium
    t.integer "bulk_transfer_id"
    t.integer "user_id"
    t.index ["source_id"], name: "source_id_idx"
  end

  create_table "tube_creation_children", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "tube_creation_id", null: false
    t.integer "tube_id", null: false
  end

  create_table "tube_rack_statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "barcode", null: false
    t.integer "status", null: false
    t.text "messages", size: :medium
    t.integer "labware_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "login"
    t.string "email"
    t.string "crypted_password", limit: 40
    t.string "salt", limit: 40
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "remember_token"
    t.datetime "remember_token_expires_at", precision: nil
    t.string "api_key"
    t.string "first_name"
    t.string "last_name"
    t.boolean "pipeline_administrator"
    t.string "barcode"
    t.string "cookie"
    t.datetime "cookie_validated_at", precision: nil
    t.string "encrypted_swipecard_code", limit: 40
    t.index ["barcode"], name: "index_users_on_barcode"
    t.index ["encrypted_swipecard_code"], name: "index_users_on_encrypted_swipecard_code"
    t.index ["login"], name: "index_users_on_login"
    t.index ["pipeline_administrator"], name: "index_users_on_pipeline_administrator"
  end

  create_table "uuids", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "resource_type", limit: 128, null: false
    t.integer "resource_id", null: false
    t.string "external_id", limit: 36, null: false
    t.index ["external_id"], name: "index_uuids_on_external_id"
    t.index ["resource_type", "resource_id"], name: "index_uuids_on_resource_type_and_resource_id"
  end

  create_table "volume_updates", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "target_id"
    t.string "created_by"
    t.float "volume_change"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "well_attributes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "well_id"
    t.string "gel_pass", limit: 20
    t.float "concentration"
    t.float "current_volume"
    t.float "buffer_volume"
    t.float "requested_volume"
    t.float "picked_volume"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "pico_pass", default: "ungraded", null: false
    t.integer "sequenom_count"
    t.string "study_id"
    t.string "gender_markers"
    t.string "gender"
    t.float "measured_volume"
    t.float "initial_volume"
    t.float "molarity"
    t.float "rin"
    t.float "robot_minimum_picking_volume"
    t.index ["well_id"], name: "index_well_attributes_on_well_id"
  end

  create_table "well_links", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "target_well_id", null: false
    t.integer "source_well_id", null: false
    t.string "type", null: false
    t.index ["target_well_id"], name: "target_well_idx"
  end

  create_table "well_to_tube_transfers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "transfer_id", null: false
    t.integer "destination_id", null: false
    t.string "source"
  end

  create_table "work_completions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "target_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["target_id"], name: "fk_rails_f8fb9e95de"
    t.index ["user_id"], name: "fk_rails_204fc81a92"
  end

  create_table "work_completions_submissions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "work_completion_id", null: false
    t.integer "submission_id", null: false
    t.index ["submission_id"], name: "fk_rails_1ac4e93988"
    t.index ["work_completion_id"], name: "fk_rails_5ea64f1af2"
  end

  create_table "work_order_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_work_order_types_on_name", unique: true
  end

  create_table "work_orders", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "work_order_type_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "state", null: false
    t.index ["work_order_type_id", "state"], name: "index_work_orders_on_work_order_type_id_and_state"
  end

  create_table "workflow_samples", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.text "name", size: :medium
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "control", default: false
    t.integer "workflow_id"
    t.integer "submission_id"
    t.string "state", limit: 20
    t.integer "size", default: 1
    t.integer "version"
  end

  create_table "workflows", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "item_limit"
    t.text "locale", size: :medium
    t.integer "pipeline_id"
    t.index ["pipeline_id"], name: "index_workflows_on_pipeline_id"
  end

  add_foreign_key "aliquot_indices", "aliquots", name: "fk_aliquot_indices_to_aliquots"
  add_foreign_key "aliquot_indices", "receptacles", column: "lane_id"
  add_foreign_key "aliquots", "primer_panels"
  add_foreign_key "aliquots", "requests"
  add_foreign_key "assets_deprecated", "plate_types", column: "labware_type_id"
  add_foreign_key "barcodes", "labware", column: "asset_id"
  add_foreign_key "flowcell_types_request_types", "flowcell_types"
  add_foreign_key "flowcell_types_request_types", "request_types"
  add_foreign_key "labware", "plate_purposes"
  add_foreign_key "labware", "plate_types", column: "labware_type_id"
  add_foreign_key "library_types_request_types", "library_types", name: "fk_library_types_request_types_to_library_types"
  add_foreign_key "library_types_request_types", "request_types", name: "fk_library_types_request_types_to_request_types"
  add_foreign_key "lot_types", "plate_purposes", column: "target_purpose_id", name: "fk_lot_types_to_plate_purposes"
  add_foreign_key "lots", "lot_types", name: "fk_lots_to_lot_types"
  add_foreign_key "messenger_creators", "plate_purposes", column: "purpose_id", name: "fk_messenger_creators_to_plate_purposes"
  add_foreign_key "pick_lists", "submissions"
  add_foreign_key "pipelines_request_types", "pipelines", name: "pipelines_request_types_ibfk_1"
  add_foreign_key "pipelines_request_types", "request_types", name: "pipelines_request_types_ibfk_2"
  add_foreign_key "plate_purposes", "barcode_prefixes"
  add_foreign_key "product_criteria", "products", name: "fk_product_criteria_to_products"
  add_foreign_key "product_product_catalogues", "product_catalogues", name: "fk_product_product_catalogues_to_product_catalogues"
  add_foreign_key "product_product_catalogues", "products", name: "fk_product_product_catalogues_to_products"
  add_foreign_key "qc_files", "labware", column: "asset_id"
  add_foreign_key "qc_metric_requests", "qc_metrics", name: "fk_qc_metric_requests_to_qc_metrics"
  add_foreign_key "qc_metric_requests", "requests", name: "fk_qc_metric_requests_to_requests"
  add_foreign_key "qc_metrics", "qc_reports", name: "fk_qc_metrics_to_qc_reports"
  add_foreign_key "qc_metrics", "receptacles", column: "asset_id"
  add_foreign_key "qc_reports", "product_criteria", column: "product_criteria_id", name: "fk_qc_reports_to_product_criteria"
  add_foreign_key "qc_reports", "studies", name: "fk_qc_reports_to_studies"
  add_foreign_key "qc_results", "qc_assays"
  add_foreign_key "qcable_creators", "users", name: "fk_qcable_creators_to_users"
  add_foreign_key "qcables", "labware", column: "asset_id"
  add_foreign_key "qcables", "lots", name: "fk_qcables_to_lots"
  add_foreign_key "receptacles", "labware"
  add_foreign_key "request_types_extended_validators", "extended_validators", name: "fk_request_types_extended_validators_to_extended_validators"
  add_foreign_key "request_types_extended_validators", "request_types", name: "fk_request_types_extended_validators_to_request_types"
  add_foreign_key "requests", "work_orders"
  add_foreign_key "roles_users", "roles", name: "fk_roles_users_to_roles"
  add_foreign_key "roles_users", "users", name: "fk_roles_users_to_users"
  add_foreign_key "sample_manifests", "plate_purposes", column: "purpose_id"
  add_foreign_key "stamp_qcables", "qcables", name: "fk_stamp_qcables_to_qcables"
  add_foreign_key "stamp_qcables", "stamps", name: "fk_stamp_qcables_to_stamps"
  add_foreign_key "stamps", "lots", name: "fk_stamps_to_lots"
  add_foreign_key "stamps", "robots", name: "fk_stamps_to_robots"
  add_foreign_key "stamps", "users", name: "fk_stamps_to_users"
  add_foreign_key "submission_templates", "product_catalogues", name: "fk_submission_templates_to_product_catalogues"
  add_foreign_key "tag2_layout_template_submissions", "submissions", name: "fk_tag2_layout_template_submissions_to_submissions"
  add_foreign_key "tag2_layout_template_submissions", "tag2_layout_templates", name: "fk_tag2_layout_template_submissions_to_tag2_layout_templates"
  add_foreign_key "tag_groups", "tag_group_adapter_types", column: "adapter_type_id"
  add_foreign_key "tag_layout_template_submissions", "submissions"
  add_foreign_key "tag_layout_template_submissions", "tag_layout_templates"
  add_foreign_key "tag_layout_templates", "tag_groups", column: "tag2_group_id"
  add_foreign_key "tag_layouts", "tag_groups", column: "tag2_group_id"
  add_foreign_key "tag_sets", "tag_groups"
  add_foreign_key "tag_sets", "tag_groups", column: "tag2_group_id"
  add_foreign_key "transfer_request_collection_transfer_requests", "transfer_request_collections"
  add_foreign_key "transfer_request_collection_transfer_requests", "transfer_requests"
  add_foreign_key "transfer_request_collections", "users"
  add_foreign_key "work_completions", "labware", column: "target_id"
  add_foreign_key "work_completions", "users"
  add_foreign_key "work_completions_submissions", "submissions"
  add_foreign_key "work_completions_submissions", "work_completions"
  add_foreign_key "work_orders", "work_order_types"
end
