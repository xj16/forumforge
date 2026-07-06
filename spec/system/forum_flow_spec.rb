# frozen_string_literal: true

require "rails_helper"

# Rack-test system spec covering the core forum flow: create a topic, reply,
# and upvote. Exercises the controllers and views end to end without JS.
RSpec.describe "Forum flow", type: :system do
  let!(:category) { create(:category, name: "General") }
  let(:user) { create(:user, username: "poster", password: "password123") }

  before do
    driven_by :rack_test
    sign_in_as(user)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"
  end

  it "creates a topic and shows it in the feed" do
    visit new_topic_path
    fill_in "Title", with: "My first ForumForge topic"
    select "General", from: "Category"
    fill_in "topic_body", with: "Hello everyone, glad to be here."
    click_button "Post topic"

    expect(page).to have_content("Topic posted.")
    expect(page).to have_content("My first ForumForge topic")

    visit root_path
    expect(page).to have_content("My first ForumForge topic")
  end

  it "lets a user reply to a topic" do
    topic = create(:topic, category: category)
    visit topic_path(topic)

    fill_in "post_body", with: "This is my reply to the discussion."
    click_button "Comment"

    expect(page).to have_content("This is my reply to the discussion.")
  end

  it "lets a user upvote a topic" do
    topic = create(:topic, category: category)
    visit topic_path(topic)

    expect {
      find("form[action='#{upvote_topic_path(topic)}'] button").click
    }.to change { topic.reload.upvotes_count }.by(1)
  end
end
