# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to have_many(:topics).dependent(:destroy) }

  it "requires a unique name" do
    create(:category, name: "General")
    expect(build(:category, name: "general")).not_to be_valid
  end

  it "orders by position then name" do
    b = create(:category, name: "Beta", position: 1)
    a = create(:category, name: "Alpha", position: 0)
    expect(Category.ordered.to_a).to eq([a, b])
  end
end
