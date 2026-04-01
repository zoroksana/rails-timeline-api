require 'rails_helper'

RSpec.describe Post, type: :model do
  subject(:post) { create(:post) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:comments).dependent(:destroy) }
  it { is_expected.to have_many(:likes).dependent(:destroy) }
  it { is_expected.to have_many(:post_attachments).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_presence_of(:description) }

  describe '.timeline_order' do
    let!(:older_post) { create(:post, date: 2.days.ago, created_at: 2.days.ago) }
    let!(:newer_post) { create(:post, date: 1.day.ago, created_at: 1.day.ago) }

    it 'sorts by date descending by default' do
      expect(described_class.timeline_order(nil, nil)).to eq([ newer_post, older_post ])
    end

    it 'sorts by created_at ascending when requested' do
      expect(described_class.timeline_order('created_at', 'asc')).to eq([ older_post, newer_post ])
    end
  end
end
