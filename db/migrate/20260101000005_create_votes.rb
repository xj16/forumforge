# frozen_string_literal: true

class CreateVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :votable, polymorphic: true, null: false

      t.timestamps null: false
    end

    # A user may vote on a given votable at most once.
    add_index :votes, %i[user_id votable_type votable_id], unique: true, name: "index_votes_uniqueness"
  end
end
