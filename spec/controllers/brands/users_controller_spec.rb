# frozen_string_literal: true

require './spec/support/sign_in_out_helpers.rb'

RSpec.describe Brands::UsersController, type: :controller do
  include SignInOutHelpers

  let(:brand) { FactoryBot.create(:brand) }

  describe 'POST create' do
    subject(:post_create) { post :create, params: { brand_id: brand.id, user_id: user.id } }

    let(:user) { FactoryBot.create(:user) }

    context 'when user is authorized' do
      let(:browsing_user) { FactoryBot.create(:user) }

      before do
        brand.users << browsing_user

        sign_in(browsing_user)
      end

      it 'adds the user to the brand' do
        expect(brand.users).not_to include(user)

        post_create

        expect(brand.reload.users).to include(user)
      end
    end

    context 'when user is not authorized' do
      it 'sets the flash' do
        expect(post_create.request).to set_flash[:alert]
      end

      it 'redirects the user' do
        expect(post_create).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE destroy' do
    subject(:delete_destroy) { delete :destroy, params: { brand_id: brand.id, id: user.id } }

    let(:user) { FactoryBot.create(:user) }

    before do
      brand.users << user
    end

    context 'when user is authorized' do
      let(:browsing_user) { FactoryBot.create(:user) }

      before do
        brand.users << browsing_user

        sign_in(browsing_user)
      end

      it 'removes the user from the brand' do
        expect(brand.users).to include(user)

        delete_destroy

        expect(brand.reload.users).not_to include(user)
      end
    end

    context 'when user is not authorized' do
      it 'sets the flash' do
        expect(delete_destroy.request).to set_flash[:alert]
      end

      it 'redirects the user' do
        expect(delete_destroy).to redirect_to(root_path)
      end
    end
  end
end
