# frozen_string_literal: true

require './spec/support/sign_in_out_helpers.rb'
require './spec/support/unauthenticated_user_examples.rb'

RSpec.describe BrandsController, type: :request do
  include SignInOutHelpers

  describe 'GET index' do
    subject(:get_index) { get '/brands' }

    let!(:brands) { FactoryBot.create_list(:brand, 2) }

    it 'shows the first page of brands' do
      get_index

      expect(response.body).to include(*brands.map(&:screen_name))
    end

    context 'when pagination is required' do
      let!(:extra_brands) { FactoryBot.create_list(:brand, 19) }

      it 'paginates brands' do
        get_index

        expect(response.body).to include(*(brands + extra_brands.first(18)).map(&:screen_name))
      end
    end
  end

  describe 'GET edit' do
    subject(:get_edit) { get "/brands/#{brand.id}/edit" }

    let(:brand) { FactoryBot.create(:brand) }

    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_account) }

      before do
        sign_in(user)
      end

      context 'when user is authorized' do
        before do
          brand.users << user
        end

        it 'renders the users list' do
          get_edit

          expect(response.body).to include(*brand.users.map(&:name))
        end

        it 'renders the add user button' do
          get_edit

          expect(response.body).to include('Add User')
        end

        it 'renders the remove user link' do
          get_edit

          expect(response.body).to include('Remove User')
        end
      end

      context 'when user is not authorized' do
        it 'sets the flash' do
          get_edit
          follow_redirect!

          expect(controller.flash[:alert]).to eq('You are not allowed to edit the brand.')
        end

        it 'redirects the user' do
          expect(get_edit).to redirect_to(root_path)
        end
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthenticated user examples'
    end
  end
end
