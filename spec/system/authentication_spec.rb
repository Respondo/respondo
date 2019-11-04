# frozen_string_literal: true

require './spec/support/omniauth_helpers.rb'
require './spec/support/sign_in_out_system_helpers.rb'

RSpec.describe 'Authentication', type: :system do
  include OmniauthHelpers
  include SignInOutSystemHelpers

  it 'allows user creation' do
    visit '/'

    add_oauth_mock(:google_oauth2, '123', { name: 'Test User', email: 'test@example.com' }, {})
    click_link('Login')
    expect(page).to have_link('User settings')
  end

  it 'redirects after sign in' do
    visit brands_path

    sign_in_user(nil, 'Login User')
    expect(page).to have_current_path(brands_path)
  end

  it 'allows brand creation' do
    visit '/'

    sign_in_user(nil, 'Login')

    add_oauth_mock(:twitter, '123', { nickname: 'test_brand' }, {})
    click_link('Authorize Brand')
    expect(page).to have_link('Brand settings')
  end

  it 'allows signing out' do
    visit '/'

    sign_in_user(nil, 'Login')
    click_link('User settings')

    click_link('(logout)')
    expect(page).to have_current_path(root_path)
  end
end
