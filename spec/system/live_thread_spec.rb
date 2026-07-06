# frozen_string_literal: true

require "rails_helper"

# JS system spec driven by Selenium + headless Chrome. Tagged `js: true` so it
# only runs where a browser is available (CI installs Chrome). It verifies that
# a reply submitted through the Turbo-powered form appears without a full page
# reload — the "live-updating thread" behaviour.
RSpec.describe "Live thread", type: :system, js: true do
  let!(:category) { create(:category, name: "General") }
  let(:user) { create(:user, username: "livetester", password: "password123") }

  before do
    sign_in_as(user)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"
  end

  it "appends a new reply without a full page reload" do
    topic = create(:topic, category: category)
    visit topic_path(topic)

    fill_in "post_body", with: "Live reply via Turbo Streams!"
    click_button "Comment"

    # The Turbo Stream broadcast appends the post into #posts.
    expect(page).to have_css("#posts", text: "Live reply via Turbo Streams!")
    expect(topic.reload.posts.count).to eq(1)
  end
end
