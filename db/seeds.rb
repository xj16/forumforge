# frozen_string_literal: true

# Seed data for local development and demos.
# Idempotent: safe to run multiple times.

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

if Topic.count.zero?
  link_topics = [
    { title: "Rails 7.1 introduces async queries", url: "https://guides.rubyonrails.org/", category: "Programming" },
    { title: "Hotwire: HTML over the wire", url: "https://hotwired.dev/", category: "Programming" },
    { title: "Show HN: I built a forum with Turbo Streams", url: "https://github.com/xj16/forumforge", category: "Show & Tell" }
  ]

  link_topics.each do |attrs|
    category = Category.find_by!(name: attrs[:category])
    Topic.create!(
      user: users.sample,
      category: category,
      title: attrs[:title],
      url: attrs[:url]
    )
  end

  text_topics = [
    { title: "Welcome to ForumForge!", body: "This is a demo community. Post links, start discussions, upvote what you like.", category: "General" },
    { title: "What are you working on this week?", body: "Share your side projects and works in progress.", category: "General" },
    { title: "Feature ideas for the forum", body: "What would make this a better place to hang out?", category: "Meta" }
  ]

  text_topics.each do |attrs|
    category = Category.find_by!(name: attrs[:category])
    topic = Topic.create!(
      user: users.sample,
      category: category,
      title: attrs[:title],
      body: attrs[:body]
    )

    # Add a few nested replies.
    root = Post.create!(user: users.sample, topic: topic, body: "Great to be here. Excited about this!")
    Post.create!(user: users.sample, topic: topic, parent: root, body: "Same! The live updates are slick.")
    Post.create!(user: users.sample, topic: topic, body: "Following for updates.")
  end

  # Cast some votes.
  Topic.find_each do |topic|
    users.sample(rand(1..4)).each do |voter|
      Vote.find_or_create_by!(user: voter, votable: topic)
    end
  end
  Post.find_each do |post|
    users.sample(rand(0..3)).each do |voter|
      Vote.find_or_create_by!(user: voter, votable: post)
    end
  end
end

# Recompute reputation synchronously for the seed data.
User.find_each(&:recalculate_reputation!)

puts "Done. #{User.count} users, #{Category.count} categories, #{Topic.count} topics, #{Post.count} posts."
puts "Log in with any of: #{users.map(&:username).join(', ')} (password: #{password})"
