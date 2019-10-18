# frozen_string_literal: true

require './spec/support/sign_in_out_helpers.rb'
require './spec/support/unauthenticated_user_examples.rb'
require './spec/support/unauthorized_user_examples.rb'

RSpec.describe Brands::UsersController, type: :request do
  include SignInOutHelpers

  let(:brand) { FactoryBot.create(:brand) }

  describe 'POST create' do
    subject(:post_create) { post "/brands/#{brand.id}/users", params: { user_id: user.id } }

    let(:user) { FactoryBot.create(:user) }

    context 'when user is signed in' do
      let(:browsing_user) { FactoryBot.create(:user, :with_account) }

      before do
        sign_in(browsing_user)
      end

      context 'when user is authorized' do
        before do
          brand.users << browsing_user
        end

        it 'adds the user to the brand' do
          expect { post_create }.to change { user.reload.brand_id }.from(nil).to(brand.id)
        end

        it 'sets the flash' do
          post_create

          expect(controller.flash[:success]).to eq('User was successfully added to the brand.')
        end

        it 'redirects to edit brand path' do
          post_create

          expect(response).to redirect_to(edit_brand_path(brand))
        end
      end

      context 'when user is not authorized' do
        include_examples 'unauthorized user examples', 'You are not allowed to edit the brand.'
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthenticated user examples'
    end
  end

  describe 'DELETE destroy' do
    subject(:delete_destroy) { delete "/brands/#{brand.id}/users/#{user.id}" }

    let(:user) { FactoryBot.create(:user) }

    before do
      brand.users << user
    end

    context 'when user is signed in' do
      let(:browsing_user) { FactoryBot.create(:user, :with_account) }

      before do
        sign_in(browsing_user)
      end

      context 'when user is authorized' do
        before do
          brand.users << browsing_user
        end

        it 'removes the user from the brand' do
          expect { delete_destroy }.to change { user.reload.brand_id }.from(brand.id).to(nil)
        end

        it 'sets the flash' do
          delete_destroy

          expect(controller.flash[:success]).to eq('User was successfully removed from the brand.')
        end

        it 'redirects to edit brand path' do
          delete_destroy

          expect(response).to redirect_to(edit_brand_path(brand))
        end

        context 'when user is removing self from brand' do
          let(:user) { browsing_user }

          it 'redirects to root path' do
            delete_destroy

            expect(response).to redirect_to(root_path)
          end
        end
      end

      context 'when user is not authorized' do
        include_examples 'unauthorized user examples', 'You are not allowed to edit the brand.'
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthenticated user examples'
    end
  end
end
