# frozen_string_literal: true

# Demo tasks for showing off the real-time nature of the forum.
#
#   bin/rails demo:seed          # ensure the DB is populated (delegates to db:seed)
#   bin/rails demo:bot           # loop: post replies + cast votes on the hot topic
#   TOPIC=slug bin/rails demo:bot  # target a specific topic
#
# `demo:bot` is meant to run alongside a browser open on a topic page: every few
# seconds it appends a reply or casts a vote as a random seeded user, and the
# viewer sees the comment and vote count animate in live via Turbo Streams —
# no second browser required. Ctrl-C to stop.
namespace :demo do
  desc "Ensure demo data exists (idempotent seed)"
  task seed: :environment do
    Rake::Task["db:seed"].invoke
  end

  desc "Continuously post replies and cast votes to animate a live thread"
  task bot: :environment do
    interval = Integer(ENV.fetch("INTERVAL", "4"))
    bots = User.where(role: "member").to_a
    bots = User.all.to_a if bots.empty?
    abort "No users found. Run `bin/rails db:seed` first." if bots.empty?

    topic =
      if ENV["TOPIC"].present?
        Topic.friendly.find(ENV["TOPIC"])
      else
        Topic.hot.first
      end
    abort "No topics found. Run `bin/rails db:seed` first." if topic.nil?

    lines = [
      "Good point — I hadn't thought of it that way.",
      "This thread keeps getting better. Watching live!",
      "Anyone have benchmarks for this?",
      "The Turbo Stream updates here are genuinely instant.",
      "Bumping this — really useful discussion.",
      "Just tried it, works great.",
      "Counterpoint: caching changes the picture entirely.",
      "Saving this for later. Thanks all."
    ]

    puts "demo:bot → topic ##{topic.id} '#{topic.title}'. Ctrl-C to stop."
    trap("INT") do
      puts "\nStopping demo:bot."
      exit
    end

    loop do
      actor = bots.sample

      if rand < 0.6
        post = topic.posts.create!(user: actor, body: lines.sample)
        puts "  💬 #{actor.username}: #{post.body}"
      else
        votable = [topic, *topic.posts.limit(20)].sample
        Vote.find_or_create_by!(user: actor, votable: votable)
        label = votable.is_a?(Topic) ? "topic" : "reply ##{votable.id}"
        puts "  ▲ #{actor.username} upvoted #{label}"
      end

      sleep interval
    end
  end
end
