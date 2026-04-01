require 'rails_helper'

RSpec.describe Like, type: :model do
  subject(:like) { create(:like) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:likable) }

  it "enforces a single like per user and likable" do
    duplicate_like = build(:like, user: like.user, likable: like.likable)

    expect(duplicate_like).not_to be_valid
    expect(duplicate_like.errors[:user_id]).to include("has already been taken")
  end
end
