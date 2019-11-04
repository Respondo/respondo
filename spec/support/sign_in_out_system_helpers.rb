# frozen_string_literal: true

require './spec/support/omniauth_helpers.rb'

# This is an abstraction on top of OmniauthHelpers for system type specs.
#
# System type specs should not include OmniauthHelpers directly for logging in -
# this module should be included instead.
module SignInOutSystemHelpers
  extend OmniauthHelpers

  def sign_in_user(user = nil, link_text = 'Login User')
    (user || FactoryBot.create(:user, :with_account)).tap do |active_user|
      SignInOutSystemHelpers.add_oauth_mock_for_user(active_user)
      click_link link_text
    end
  end

  def sign_in_brand(brand = nil, link_text = 'Login Brand')
    (brand || FactoryBot.create(:brand)).tap do |active_brand|
      SignInOutSystemHelpers.add_oauth_mock_for_brand(active_brand)
      click_link link_text
    end
  end
end