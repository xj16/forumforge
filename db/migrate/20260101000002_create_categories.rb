# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string  :name,         null: false
      t.string  :slug,         null: false
      t.string  :description
      t.integer :position,     null: false, default: 0
      t.integer :topics_count, null: false, default: 0

      t.timestamps null: false
    end

    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
    add_index :categories, :position
  end
end
