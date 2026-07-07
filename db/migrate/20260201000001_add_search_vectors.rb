# frozen_string_literal: true

# Full-text search support.
#
# We add a STORED, generated `tsvector` column to topics and posts plus a GIN
# index on each. Generated columns keep the search vector in sync automatically
# on every INSERT/UPDATE — no triggers, no application code, and no extra gem.
#
# Topic weighting: the title is weight A (most important), the body/url weight
# B, so a title match ranks above a body match for the same query.
class AddSearchVectors < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE topics
        ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(body,  '')), 'B') ||
          setweight(to_tsvector('english', coalesce(url,   '')), 'B')
        ) STORED
    SQL
    add_index :topics, :search_vector, using: :gin

    execute <<~SQL
      ALTER TABLE posts
        ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (
          to_tsvector('english', coalesce(body, ''))
        ) STORED
    SQL
    add_index :posts, :search_vector, using: :gin
  end

  def down
    remove_index :posts, :search_vector
    remove_column :posts, :search_vector
    remove_index :topics, :search_vector
    remove_column :topics, :search_vector
  end
end
