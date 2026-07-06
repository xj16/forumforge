# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Forum profile
      t.string  :username,   null: false
      t.string  :slug,       null: false
      t.string  :role,       null: false, default: "member"
      t.integer :reputation, null: false, default: 0

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :username,             unique: true
    add_index :users, :slug,                 unique: true
    add_index :users, :reputation
  end
end
