# frozen_string_literal: true

require "pagy/extras/overflow"

# Default items per page for topic and post listings.
Pagy::DEFAULT[:limit] = 25
Pagy::DEFAULT[:overflow] = :last_page
