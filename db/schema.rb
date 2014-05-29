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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140530062752) do

  create_table "associate_maintainers", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "associate_maintainers", ["project_id"], :name => "index_associate_maintainers_on_project_id"
  add_index "associate_maintainers", ["user_id"], :name => "index_associate_maintainers_on_user_id"

  create_table "associate_projects_projects", :force => true do |t|
    t.integer "project_id",           :null => false
    t.integer "associate_project_id", :null => false
  end

  add_index "associate_projects_projects", ["associate_project_id"], :name => "index_associate_projects_projects_on_associate_project_id"
  add_index "associate_projects_projects", ["project_id"], :name => "index_associate_projects_projects_on_project_id"

  create_table "blocks", :force => true do |t|
    t.string   "hid"
    t.integer  "doc_id"
    t.integer  "begin"
    t.integer  "end"
    t.string   "category"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "blocks", ["doc_id"], :name => "index_blocks_on_doc_id"
  add_index "blocks", ["project_id"], :name => "index_blocks_on_project_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "denotations", :force => true do |t|
    t.string   "hid"
    t.integer  "doc_id"
    t.integer  "begin"
    t.integer  "end"
    t.string   "obj"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "denotations", ["doc_id"], :name => "index_denotations_on_doc_id"
  add_index "denotations", ["project_id"], :name => "index_denotations_on_project_id"

  create_table "docs", :force => true do |t|
    t.text     "body"
    t.string   "source"
    t.string   "sourcedb"
    t.string   "sourceid"
    t.integer  "serial"
    t.string   "section"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "denotations_count", :default => 0
    t.integer  "subcatrels_count",  :default => 0
  end

  add_index "docs", ["serial"], :name => "index_docs_on_serial"
  add_index "docs", ["sourcedb"], :name => "index_docs_on_sourcedb"
  add_index "docs", ["sourceid"], :name => "index_docs_on_sourceid"

  create_table "docs_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "doc_id"
  end

  add_index "docs_projects", ["project_id", "doc_id"], :name => "index_docs_projects_on_project_id_and_doc_id", :unique => true

  create_table "documentation_categories", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "documentations", :force => true do |t|
    t.string  "title",                     :null => false
    t.text    "body",                      :null => false
    t.integer "documentation_category_id"
  end

  add_index "documentations", ["documentation_category_id"], :name => "index_documentations_on_documentation_category_id"

  create_table "instances", :force => true do |t|
    t.string   "hid"
    t.integer  "obj_id"
    t.string   "pred"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "instances", ["obj_id"], :name => "index_instances_on_obj_id"
  add_index "instances", ["project_id"], :name => "index_instances_on_project_id"

  create_table "modifications", :force => true do |t|
    t.string   "hid"
    t.integer  "obj_id"
    t.string   "obj_type"
    t.string   "pred"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "modifications", ["obj_id"], :name => "index_modifications_on_obj_id"
  add_index "modifications", ["project_id"], :name => "index_modifications_on_project_id"

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "author"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.string   "license"
    t.string   "reference"
    t.string   "editor"
    t.integer  "accessibility"
    t.integer  "status"
    t.integer  "user_id"
    t.string   "viewer"
    t.string   "rdfwriter"
    t.string   "xmlwriter"
    t.string   "bionlpwriter"
    t.string   "type"
    t.integer  "pmdocs_count",                     :default => 0
    t.integer  "pmcdocs_count",                    :default => 0
    t.integer  "denotations_count",                :default => 0
    t.integer  "relations_count",                  :default => 0
    t.integer  "pending_associate_projects_count", :default => 0
    t.boolean  "annotations_zip_downloadable",     :default => true
    t.datetime "annotations_updated_at",           :default => '2014-04-09 12:41:19'
  end

  add_index "projects", ["name"], :name => "index_annsets_on_name", :unique => true
  add_index "projects", ["name"], :name => "index_projects_on_name", :unique => true

  create_table "relations", :force => true do |t|
    t.string   "hid"
    t.integer  "subj_id"
    t.string   "subj_type"
    t.integer  "obj_id"
    t.string   "obj_type"
    t.string   "pred"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "relations", ["obj_id"], :name => "index_relations_on_obj_id"
  add_index "relations", ["project_id"], :name => "index_relations_on_project_id"
  add_index "relations", ["subj_id"], :name => "index_relations_on_subj_id"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "username"
    t.boolean  "root",                   :default => false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
