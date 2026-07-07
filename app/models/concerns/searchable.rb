# frozen_string_literal: true

# Full-text search backed by a Postgres generated `tsvector` column
# (`search_vector`) and a GIN index. Mixed into Topic and Post.
#
# `search` is safe against injection: the raw query string is bound as a
# parameter and turned into a tsquery by Postgres (`websearch_to_tsquery`),
# never interpolated into SQL. Results are ordered by `ts_rank` relevance.
module Searchable
  extend ActiveSupport::Concern

  # Postgres text-search configuration used by the generated column and here.
  TS_CONFIG = "english"

  # Unicode sentinels ts_headline wraps matches in. They contain none of the
  # characters HTML-escaping touches (< > & " '), so we can escape the whole
  # snippet first — neutralising any HTML in the underlying user text — and
  # only then swap the sentinels for real <mark> tags. XSS-safe by design.
  HL_START = "❰hl❱"  # ❰hl❱
  HL_STOP  = "❲hl❳"  # ❲hl❳

  class_methods do
    # Returns records matching `query`, most relevant first. Blank queries
    # return an empty relation so callers can render an empty state cheaply.
    def search(query)
      cleaned = query.to_s.strip
      return none if cleaned.blank?

      order = sanitize_sql_array(["ts_rank(search_vector, websearch_to_tsquery(?, ?)) DESC, created_at DESC", TS_CONFIG, cleaned])
      where("search_vector @@ websearch_to_tsquery(:cfg, :q)", cfg: TS_CONFIG, q: cleaned).order(Arel.sql(order))
    end
  end

  # A short, HTML-safe snippet of `field` with matched terms wrapped in <mark>.
  def search_highlight(field, query, max_words: 30, min_words: 15)
    helpers = ActionController::Base.helpers
    cleaned = query.to_s.strip
    text = public_send(field).to_s
    return helpers.truncate(text, length: 160) if cleaned.blank?

    opts = "StartSel=#{HL_START}, StopSel=#{HL_STOP}, MaxWords=#{max_words.to_i}, MinWords=#{min_words.to_i}, ShortWord=2, HighlightAll=FALSE"
    sql = self.class.sanitize_sql_array([
      "SELECT ts_headline(:cfg, :text, websearch_to_tsquery(:cfg, :q), :opts)",
      { cfg: TS_CONFIG, text: text, q: cleaned, opts: opts }
    ])
    raw_snippet = self.class.connection.select_value(sql) || text
    marked = helpers.html_escape(raw_snippet).gsub(HL_START, "<mark>").gsub(HL_STOP, "</mark>")
    marked.html_safe # rubocop:disable Rails/OutputSafety
  end
end
