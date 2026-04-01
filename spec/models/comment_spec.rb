require 'rails_helper'

RSpec.describe Comment, type: :model do
  subject(:comment) { build(:comment) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:post) }
  it { is_expected.to have_many(:likes).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:body) }
end
