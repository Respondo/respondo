# typed: strict
# frozen_string_literal: true

class Brand < ApplicationRecord
  extend T::Sig

  validates :external_uid, presence: true, allow_blank: false, uniqueness: true
  validates :screen_name, presence: true, allow_blank: false

  attr_encrypted :token, key: attr_encrypted_encryption_key
  attr_encrypted :secret, key: attr_encrypted_encryption_key

  has_many :users, dependent: :nullify
  has_many :tickets, dependent: :restrict_with_error

  class << self
    extend T::Sig

    sig { params(auth: T.untyped).returns(Brand) }
    def from_omniauth(auth)
      find_or_initialize_by(external_uid: auth.uid).tap do |brand|
        brand.screen_name = auth.info.nickname

        brand.token = auth.credentials.token
        brand.secret = auth.credentials.secret

        brand.save!
      end
    end
  end

  sig { returns(T::Array[Twitter::Tweet]) }
  def new_mentions
    twitter.mentions_timeline(since: last_ticket_id, tweet_mode: 'extended')
  end

  sig { returns(Clients::Twitter) }
  def twitter
    @twitter ||=
      Clients::Twitter.new do |config|
        config.consumer_key        = ENV['TWITTER_API_KEY']
        config.consumer_secret     = ENV['TWITTER_API_SECRET']
        config.access_token        = token
        config.access_token_secret = secret
      end
  end

  private

  sig { returns(T.nilable(String)) }
  def last_ticket_id
    tickets.last&.external_uid
  end
end
