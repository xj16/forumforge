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

ActiveRecord::Schema[7.1].define(version: 2026_02_01_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "description"
    t.integer "position", default: 0, null: false
    t.integer "topics_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_uniqueness", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.bigint "actor_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.string "action", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id", null: false
    t.bigint "parent_id"
    t.text "body", null: false
    t.integer "upvotes_count", default: 0, null: false
    t.integer "replies_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "search_vector", type: :tsvector, as: "to_tsvector('english'::regconfig, COALESCE(body, ''::text))", stored: true
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["search_vector"], name: "index_posts_on_search_vector", using: :gin
    t.index ["topic_id"], name: "index_posts_on_topic_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.text "body"
    t.string "url"
    t.integer "upvotes_count", default: 0, null: false
    t.integer "posts_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "search_vector", type: :tsvector, as: "((setweight(to_tsvector('english'::regconfig, COALESCE(title, ''::character varying)::text), 'A'::\"char\") || setweight(to_tsvector('english'::regconfig, COALESCE(body, ''::text)), 'B'::\"char\")) || setweight(to_tsvector('english'::regconfig, COALESCE(url, ''::character varying)::text), 'B'::\"char\"))", stored: true
    t.index ["category_id"], name: "index_topics_on_category_id"
    t.index ["created_at"], name: "index_topics_on_created_at"
    t.index ["search_vector"], name: "index_topics_on_search_vector", using: :gin
    t.index ["slug"], name: "index_topics_on_slug", unique: true
    t.index ["upvotes_count"], name: "index_topics_on_upvotes_count"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username", null: false
    t.string "slug", null: false
    t.string "role", default: "member", null: false
    t.integer "reputation", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reputation"], name: "index_users_on_reputation"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "votable_type", null: false
    t.bigint "votable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "votable_type", "votable_id"], name: "index_votes_uniqueness", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
    t.index ["votable_type", "votable_id"], name: "index_votes_on_votable"
  end

  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "posts", "posts", column: "parent_id"
  add_foreign_key "posts", "topics"
  add_foreign_key "posts", "users"
  add_foreign_key "topics", "categories"
  add_foreign_key "topics", "users"
  add_foreign_key "votes", "users"
end
