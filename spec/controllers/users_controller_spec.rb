# frozen_string_literal: true

require './spec/support/sign_in_out_helpers.rb'

RSpec.describe UsersController, type: :controller do
  include SignInOutHelpers

  describe 'GET edit' do
    subject(:get_edit) { get :edit, params: { id: user.id } }

    let(:user) { FactoryBot.create(:user) }

    it 'sets the user' do
      get_edit

      expect(assigns(:user)).to eq(user)
    end

    context 'when user is authorized' do
      before do
        sign_in(user)
      end

      it 'renders the edit template' do
        expect(get_edit).to render_template('users/edit')
      end
    end

    context 'when user is not authorized' do
      it 'sets the flash' do
        expect(get_edit.request).to set_flash[:alert]
      end

      it 'redirects the user' do
        expect(get_edit).to redirect_to(root_path)
      end
    end
  end
end
