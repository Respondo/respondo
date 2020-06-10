# frozen_string_literal: true

RSpec.describe BrandPolicy do
  subject(:brand_policy) { described_class }

  let(:brand) { FactoryBot.create(:brand) }

  permissions :subscription? do
    it 'allows if subscription checks are skipped' do
      allow(Flipper).to receive(:enabled?).with(:skip_subscription_check).and_return(true)

      expect(brand_policy).to permit(nil, brand)
    end

    it 'allows if brand has subscription' do
      FactoryBot.create(:subscription, brand: brand)

      expect(brand_policy).to permit(nil, brand)
    end

    it 'denies if brand does not have subscription' do
      expect(brand_policy).not_to permit(nil, brand)
    end
  end
end