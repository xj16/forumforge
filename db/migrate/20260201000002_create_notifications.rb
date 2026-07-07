# frozen_string_literal: true

# In-app notifications.
#
# A notification records that `actor` did something (`action`) involving
# `notifiable` (a Post, Topic, …) that `recipient` should hear about — a reply
# to their content, a mention, or an upvote. `read_at` tracks the unread badge.
class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor,     null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string   :action,  null: false
      t.datetime :read_at

      t.timestamps null: false
    end

    # The inbox lists a user's notifications newest-first…
    add_index :notifications, %i[recipient_id created_at]
    # …and the unread badge counts where read_at IS NULL for a recipient.
    add_index :notifications, %i[recipient_id read_at]
  end
end
