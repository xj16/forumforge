# frozen_string_literal: true

# Give asynchronous Turbo Stream broadcasts a generous window to arrive over
# the websocket before a matcher gives up (CI can be slow to boot Chrome).
Capybara.default_max_wait_time = 10

# Use the app host consistently.
Capybara.server = :puma, { Silent: true }
