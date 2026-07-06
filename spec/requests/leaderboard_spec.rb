# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Leaderboard", type: :request do
  it "lists users ordered by reputation" do
    create(:user, username: "lowrep", reputation: 5)
    create(:user, username: "highrep", reputation: 500)

    get leaderboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body.index("highrep")).to be < response.body.index("lowrep")
  end
end
