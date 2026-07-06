# frozen_string_literal: true

# Point values awarded for community activity. Centralised here so the rules
# are easy to audit and tune. Referenced by User#recalculate_reputation! and
# the ReputationJob.
module Reputation
  TOPIC_UPVOTE  = 10
  POST_UPVOTE   = 5
  TOPIC_CREATED = 2
  POST_CREATED  = 1
end
