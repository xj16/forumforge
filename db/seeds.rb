# frozen_string_literal: true

# Seed data for local development and demos.
# Idempotent: safe to run multiple times.
#
# Produces a realistic, populated forum: categories, users (one admin), link
# and text topics, threaded replies with a couple of @mentions (which create
# real notifications), and a spread of votes so the hot/top feeds and the
# leaderboard have something to show. See also `rake demo:bot` for live
# activity that animates a thread in real time.

puts "Seeding ForumForge..."

categories = [
  { name: "General", description: "Anything and everything.", position: 0 },
  { name: "Programming", description: "Code, tools, and computer science.", position: 1 },
  { name: "Show & Tell", description: "Share what you built.", position: 2 },
  { name: "Meta", description: "About the forum itself.", position: 3 }
].map { |attrs| Category.find_or_create_by!(name: attrs[:name]) { |c| c.assign_attributes(attrs) } }

password = "password123"

users = %w[ada linus grace dennis margaret].map do |name|
  User.find_or_create_by!(username: name) do |u|
    u.email = "#{name}@example.com"
    u.password = password
    u.password_confirmation = password
  end
end

admin = User.find_or_create_by!(username: "admin") do |u|
  u.email = "admin@example.com"
  u.password = password
  u.password_confirmation = password
  u.role = "admin"
end
users << admin

# Give one member the moderator role so the role system is visible in the demo.
users.find { |u| u.username == "grace" }&.update!(role: "moderator")

if Topic.count.zero?
  link_topics = [
    { title: "Rails 7.1 introduces async queries", url: "https://guides.rubyonrails.org/", category: "Programming" },
    { title: "Hotwire: HTML over the wire", url: "https://hotwired.dev/", category: "Programming" },
    { title: "Postgres full-text search is underrated", url: "https://www.postgresql.org/docs/current/textsearch.html", category: "Programming" },
    { title: "Show HN: I built a forum with Turbo Streams", url: "https://github.com/xj16/forumforge", category: "Show & Tell" }
  ]

  link_topics.each do |attrs|
    category = Category.find_by!(name: attrs[:category])
    Topic.create!(user: users.sample, category: category, title: attrs[:title], url: attrs[:url])
  end

  text_topics = [
    { title: "Welcome to ForumForge!", body: "This is a demo community. Post links, start discussions, upvote what you like. Try the search box up top — it does live full-text search over topics and comments.", category: "General" },
    { title: "What are you working on this week?", body: "Share your side projects and works in progress. I'm deep in a Rails + Hotwire app with real-time Turbo Stream updates.", category: "General" },
    { title: "How do live updates work here?", body: "New replies and vote counts stream in over Action Cable without a page reload. cc @ada — you asked about this.", category: "Meta" },
    { title: "Feature ideas for the forum", body: "What would make this a better place to hang out? Notifications and search just landed.", category: "Meta" }
  ]

  text_topics.each do |attrs|
    category = Category.find_by!(name: attrs[:category])
    topic = Topic.create!(user: users.sample, category: category, title: attrs[:title], body: attrs[:body])

    root = Post.create!(user: users.sample, topic: topic, body: "Great to be here. Excited about this! The full-text search is slick.")
    Post.create!(user: users.sample, topic: topic, parent: root, body: "Same! The live updates via Turbo Streams are the best part. cc @linus")
    Post.create!(user: users.sample, topic: topic, body: "Following for updates. Nice work on the notifications.")
  end

  # Cast some votes across topics and posts.
  Topic.find_each do |topic|
    users.sample(rand(1..4)).each { |voter| Vote.find_or_create_by!(user: voter, votable: topic) }
  end
  Post.find_each do |post|
    users.sample(rand(0..3)).each { |voter| Vote.find_or_create_by!(user: voter, votable: post) }
  end
end

# Recompute reputation synchronously for the seed data.
User.find_each(&:recalculate_reputation!)

# Create the @mention notifications so the demo comes up with unread bells
# already populated. Best-effort: if the mail/queue backend isn't up during
# seeding, don't fail the whole seed over notifications.
Post.find_each do |post|
  NotifyMentionsJob.perform_now(post.id)
rescue StandardError => e
  warn "  (skipped mention notification for post ##{post.id}: #{e.message})"
end

puts "Done. #{User.count} users, #{Category.count} categories, #{Topic.count} topics, " \
     "#{Post.count} posts, #{Vote.count} votes, #{Notification.count} notifications."
puts "Log in with any of: #{users.map(&:username).join(', ')} (password: #{password})"
puts "  • grace is a moderator, admin is an admin (Sidekiq UI at /sidekiq)."
