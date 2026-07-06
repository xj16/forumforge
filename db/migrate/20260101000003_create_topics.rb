# frozen_string_literal: true

class CreateTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string  :title,         null: false
      t.string  :slug,          null: false
      t.text    :body
      t.string  :url
      t.integer :upvotes_count, null: false, default: 0
      t.integer :posts_count,   null: false, default: 0

      t.timestamps null: false
    end

    add_index :topics, :slug, unique: true
    add_index :topics, :created_at
    add_index :topics, :upvotes_count
  end
end
