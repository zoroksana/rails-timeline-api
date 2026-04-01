require 'rails_helper'

RSpec.describe PostAttachment, type: :model do
  subject(:post_attachment) { build(:post_attachment) }

  it { is_expected.to belong_to(:post) }

  it { is_expected.to validate_presence_of(:file_type) }
  it { is_expected.to validate_presence_of(:url) }

  it "validates supported file types" do
    post_attachment.file_type = "audio"

    expect(post_attachment).not_to be_valid
    expect(post_attachment.errors[:file_type]).to include("is not included in the list")
  end
end
