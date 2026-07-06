# frozen_string_literal: true

require "rails_helper"

# Rack-test system spec (no JS) — verifies the full sign-up / sign-in flow.
RSpec.describe "Authentication", type: :system do
  it "lets a visitor sign up" do
    visit new_user_registration_path

    fill_in "Username", with: "newbie"
    fill_in "Email", with: "newbie@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_content("newbie")
    expect(User.find_by(username: "newbie")).to be_present
  end

  it "lets an existing user sign in and out" do
    create(:user, username: "returning", email: "returning@example.com", password: "password123")

    visit new_user_session_path
    fill_in "Email", with: "returning@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_link("returning")

    click_button "Sign out"
    expect(page).to have_link("Sign in")
  end
end
