# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.references :user,   null: false, foreign_key: true
      t.references :topic,  null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :posts }
      t.text    :body,          null: false
      t.integer :upvotes_count, null: false, default: 0
      t.integer :replies_count, null: false, default: 0

      t.timestamps null: false
    end

    add_index :posts, :created_at
  end
end
