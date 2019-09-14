# frozen_string_literal: true

RSpec.describe User, type: :model do
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:brand).optional }
    it { is_expected.to have_many(:accounts) }
  end

  describe '.not_in_brand' do
    let(:brand) { FactoryBot.create(:brand) }
    let!(:user_outside_brand) { FactoryBot.create(:user) }

    subject { User.not_in_brand(brand.id) }

    before do
      brand.users << FactoryBot.create(:user)
    end

    it 'returns just the user outside brand' do
      expect(subject).to contain_exactly(user_outside_brand)
    end
  end
end
