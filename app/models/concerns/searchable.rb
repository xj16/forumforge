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

  class_methods do
    # Returns records matching `query`, most relevant first. Blank queries
    # return an empty relation so callers can render an empty state cheaply.
    def search(query)
      cleaned = query.to_s.strip
      return none if cleaned.blank?

      order = sanitize_sql_array([ "ts_rank(search_vector, websearch_to_tsquery(?, ?)) DESC, created_at DESC", TS_CONFIG, cleaned ])
      where("search_vector @@ websearch_to_tsquery(:cfg, :q)", cfg: TS_CONFIG, q: cleaned).order(Arel.sql(order))
    end
  end

  # A short, HTML-safe snippet of `field` with matched terms wrapped in <mark>.
  #
  # XSS-safe by construction: we HTML-escape the source text BEFORE handing it
  # to ts_headline, so any markup in the user's content becomes inert entities
  # (`&lt;script&gt;`). ts_headline then wraps only the matched query terms in
  # literal `<mark>`/`</mark>` tags, which are the only live markup in the
  # result — hence html_safe.
  def search_highlight(field, query, max_words: 30, min_words: 15)
    cleaned = query.to_s.strip
    text = public_send(field).to_s
    return ERB::Util.html_escape(ActionController::Base.helpers.truncate(text, length: 160)) if cleaned.blank?

    escaped = ERB::Util.html_escape(text).to_s
    opts = "StartSel=<mark>, StopSel=</mark>, MaxWords=#{max_words.to_i}, MinWords=#{min_words.to_i}, ShortWord=2, HighlightAll=FALSE"
    sql = self.class.sanitize_sql_array([
      "SELECT ts_headline(:cfg, :text, websearch_to_tsquery(:cfg, :q), :opts)",
      { cfg: TS_CONFIG, text: escaped, q: cleaned, opts: opts }
    ])
    snippet = self.class.connection.select_value(sql) || escaped
    snippet.html_safe # rubocop:disable Rails/OutputSafety
  end
end
