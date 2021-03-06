# frozen_string_literal: true

require './spec/support/sign_in_out_request_helpers'
require './spec/support/unauthorized_user_examples'

RSpec.describe Brands::TicketsController, type: :request do
  include SignInOutRequestHelpers

  let(:brand) { FactoryBot.create(:brand) }

  describe 'GET index' do
    subject(:get_index) { get "/brands/#{brand.id}/tickets", params: { status: status, query: query } }

    context 'without search' do
      let(:query) { nil }

      context 'when pagination is not required' do
        let!(:open_ticket) { FactoryBot.create(:internal_ticket, status: :open, brand: brand).base_ticket }
        let!(:solved_ticket) { FactoryBot.create(:internal_ticket, status: :solved, brand: brand).base_ticket }

        context 'when status parameter is not specified' do
          let(:status) { nil }

          it 'renders open tickets' do
            get_index

            expect(response.body).to include(open_ticket.content)
          end
        end

        context 'when status parameter is empty string' do
          let(:status) { '' }

          it 'renders open tickets' do
            get_index

            expect(response.body).to include(open_ticket.content)
          end
        end

        context 'when status parameter is open' do
          let(:status) { 'open' }

          it 'renders open tickets' do
            get_index

            expect(response.body).to include(open_ticket.content)
          end
        end

        context 'when status parameter is solved' do
          let(:status) { 'solved' }

          it 'renders solved tickets' do
            get_index

            expect(response.body).to include(solved_ticket.content)
          end
        end
      end

      context 'when pagination is required' do
        let!(:open_tickets) { FactoryBot.create_list(:internal_ticket, 21, status: :open, brand: brand).map(&:base_ticket) }

        it 'paginates tickets' do
          get_index

          expect(response.body).to include(*open_tickets.first(20).map(&:content))
        end

        it 'does not show page two tickets' do
          get_index

          expect(response.body).not_to include(open_tickets.last.content)
        end
      end
    end

    context 'when searching by author name' do
      let(:tickets) { FactoryBot.create_list(:internal_ticket, 2, brand: brand).map(&:base_ticket) }
      let(:query) { tickets.first.author.username }

      it 'shows matching tickets' do
        get_index

        expect(response.body).to include(tickets.first.content)
      end

      it 'does not show other tickets' do
        get_index

        expect(response.body).not_to include(tickets.second.content)
      end
    end

    context 'when searching by ticket content' do
      let(:tickets) { FactoryBot.create_list(:internal_ticket, 2, brand: brand).map(&:base_ticket) }
      let(:query) { tickets.first.content }

      it 'shows matching tickets' do
        get_index

        expect(response.body).to include(tickets.first.content)
      end

      it 'does not show other tickets' do
        get_index

        expect(response.body).not_to include(tickets.second.content)
      end
    end
  end

  describe 'GET show' do
    subject(:get_show) { get "/brands/#{brand.id}/tickets/#{ticket.id}" }

    let!(:ticket) { FactoryBot.create(:internal_ticket, provider: 'twitter', brand: brand).base_ticket }

    context 'when user is not signed in' do
      it 'shows the ticket' do
        get_show

        expect(response.body).to include(ticket.content)
      end
    end
  end

  describe 'POST reply' do
    subject(:post_reply) { post "/brands/#{brand.id}/tickets/#{ticket.id}/reply", params: { response_text: 'does not matter' } }

    let!(:ticket) { FactoryBot.create(:internal_ticket, provider: 'twitter', brand: brand).base_ticket }
    let(:client) { instance_spy(Clients::Client) }
    let(:twitter_client_class) { class_spy(Clients::Twitter, new: client) }
    let(:disqus_client_class) { class_spy(Clients::Disqus, new: client) }
    let(:external_client_class) { class_spy(Clients::External, new: client) }

    before do
      stub_const(Clients::Twitter.to_s, twitter_client_class)
      stub_const(Clients::Disqus.to_s, disqus_client_class)
      stub_const(Clients::External.to_s, external_client_class)
    end

    shared_examples 'valid reply' do
      it 'replies to the ticket' do
        post_reply

        expect(client).to have_received(:reply).with('does not matter', ticket.external_uid)
      end

      it 'creates a reply ticket' do
        expect { post_reply }.to change(Ticket, :count).from(1).to(2)
      end

      it 'creates a reply ticket with matching attributes' do
        post_reply

        expect(ticket.replies.first).to have_attributes(parent: ticket, content: instance_of(String))
      end

      it 'sets the flash' do
        post_reply

        expect(controller.flash[:success]).to eq('Response was successfully submitted.')
      end

      it 'redirects to brand tickets path' do
        post_reply

        expect(response).to redirect_to(brand_tickets_path(brand))
      end
    end

    shared_examples 'invalid reply' do
      it 'does not create a reply ticket' do
        expect { post_reply }.not_to change(Ticket, :count).from(1)
      end

      it 'sets the flash' do
        post_reply

        expect(controller.flash[:warning]).to eq("Unable to create tweet.\nerror")
      end

      it 'redirects to brand tickets path' do
        post_reply

        expect(response).to redirect_to(brand_tickets_path(brand))
      end
    end

    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }

      before do
        FactoryBot.create(:user_account, provider: 'google_oauth2', user: user)
        sign_in(user)
      end

      context 'when ticket is internal' do
        (Ticket.providers.keys - ['external']).each do |provider|
          context "when ticket provider is #{provider}" do
            let(:ticket) { FactoryBot.create(:internal_ticket, provider: provider, brand: brand).base_ticket }

            let(:client_error) { Twitter::Error::Forbidden.new('error') }
            let(:client_response) do
              case provider
              when 'twitter'
                instance_double(
                  Twitter::Tweet,
                  JSON.parse(file_fixture('twitter_post_hash.json').read).merge(
                    in_reply_to_tweet_id: ticket.external_uid,
                    user: instance_double(Twitter::User, id: '2', screen_name: 'test')
                  ).deep_symbolize_keys
                )
              when 'disqus'
                JSON.parse(file_fixture('disqus_post_hash.json').read).merge(parent: ticket.external_uid).deep_symbolize_keys
              end
            end

            context 'when authorized as a user' do
              before do
                FactoryBot.create(:user_account, provider: provider, user: user)
              end

              context 'when brand has subscription' do
                before do
                  FactoryBot.create(:subscription, brand: brand)
                end

                context 'when reply is valid' do
                  before do
                    allow(client).to receive(:reply).and_return(client_response)
                  end

                  it_behaves_like 'valid reply'
                end

                context 'when reply is invalid' do
                  before do
                    allow(client).to receive(:reply).and_raise(client_error)
                  end

                  it_behaves_like 'invalid reply'
                end
              end

              context 'when brand does not have subscription' do
                include_examples 'unauthorized user examples', 'You do not have an active subscription.'
              end
            end

            context 'when authorized as a brand' do
              before do
                FactoryBot.create(:brand_account, provider: provider, brand: brand)

                user.update!(brand: brand)
              end

              context 'when brand has subscription' do
                before do
                  FactoryBot.create(:subscription, brand: brand)
                end

                context 'when reply is valid' do
                  before do
                    allow(client).to receive(:reply).and_return(client_response)
                  end

                  it_behaves_like 'valid reply'
                end

                context 'when reply is invalid' do
                  before do
                    allow(client).to receive(:reply).and_raise(client_error)
                  end

                  it_behaves_like 'invalid reply'
                end
              end

              context 'when brand does not have subscription' do
                include_examples 'unauthorized user examples', 'You do not have an active subscription.'
              end
            end

            context 'when user is not authorized' do
              include_examples 'unauthorized user examples', 'You are not authorized.'
            end
          end
        end
      end

      context 'when ticket is external' do
        let(:ticket) { FactoryBot.create(:external_ticket, brand: brand).base_ticket }

        let(:client_error) { Twitter::Error::Forbidden.new('error') }
        let(:client_response) do
          JSON.parse(file_fixture('external_post_hash.json').read).merge(parent_uid: ticket.external_uid).to_json
        end

        context 'when authorized as a user' do
          before do
            FactoryBot.create(:user_account, provider: 'twitter', user: user)
          end

          context 'when brand has subscription' do
            before do
              FactoryBot.create(:subscription, brand: brand)
            end

            context 'when reply is valid' do
              before do
                allow(client).to receive(:reply).and_return(client_response)
              end

              include_examples 'unauthorized user examples', 'You are not authorized.'
            end

            context 'when reply is invalid' do
              before do
                allow(client).to receive(:reply).and_raise(client_error)
              end

              include_examples 'unauthorized user examples', 'You are not authorized.'
            end
          end

          context 'when brand does not have subscription' do
            include_examples 'unauthorized user examples', 'You are not authorized.'
          end
        end

        context 'when authorized as a brand' do
          before do
            FactoryBot.create(:brand_account, provider: 'twitter', brand: brand)

            user.update!(brand: brand)
          end

          context 'when brand has subscription' do
            before do
              FactoryBot.create(:subscription, brand: brand)
            end

            context 'when reply is valid' do
              before do
                allow(client).to receive(:reply).and_return(client_response)
              end

              it_behaves_like 'valid reply'
            end

            context 'when reply is invalid' do
              before do
                allow(client).to receive(:reply).and_raise(client_error)
              end

              it_behaves_like 'invalid reply'
            end
          end

          context 'when brand does not have subscription' do
            include_examples 'unauthorized user examples', 'You do not have an active subscription.'
          end
        end

        context 'when user is not authorized' do
          include_examples 'unauthorized user examples', 'You are not authorized.'
        end
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthorized user examples', 'You are not authorized.'
    end
  end

  describe 'POST internal_note' do
    subject(:post_internal_note) do
      post "/brands/#{brand.id}/tickets/#{ticket.id}/internal_note",
           params: { internal_note_text: internal_note_text }
    end

    let(:ticket) { FactoryBot.create(:internal_ticket, brand: brand).base_ticket }
    let(:internal_note_text) { nil }

    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_account) }

      before do
        sign_in(user)
      end

      context 'when user is authorized' do
        before do
          user.update!(brand: brand)
        end

        context 'when brand has subscription' do
          before do
            FactoryBot.create(:subscription, brand: brand)
          end

          context 'when internal note is valid' do
            let(:internal_note_text) { 'does not matter' }

            it 'creates an internal note' do
              expect { post_internal_note }.to change(InternalNote, :count).from(0).to(1)
            end

            it 'sets the flash' do
              post_internal_note

              expect(controller.flash[:success]).to eq('Internal note was successfully submitted.')
            end

            it 'redirects to brand tickets path' do
              post_internal_note

              expect(response).to redirect_to(brand_tickets_path(brand))
            end
          end

          context 'when internal note is not valid' do
            it 'does not create an internal note' do
              expect { post_internal_note }.not_to change(InternalNote, :count)
            end

            it 'sets the flash' do
              post_internal_note

              expect(controller.flash[:warning]).to eq('Unable to create internal note.')
            end

            it 'redirects to brand tickets path' do
              post_internal_note

              expect(response).to redirect_to(brand_tickets_path(brand))
            end
          end
        end

        context 'when brand does not have subscription' do
          include_examples 'unauthorized user examples', 'You do not have an active subscription.'
        end
      end

      context 'when user is not authorized' do
        include_examples 'unauthorized user examples', 'You are not authorized.'
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthorized user examples', 'You are not authorized.'
    end
  end

  describe 'POST invert_status' do
    subject(:post_invert_status) { post "/brands/#{brand.id}/tickets/#{ticket.id}/invert_status" }

    let(:ticket) { FactoryBot.create(:internal_ticket, brand: brand).base_ticket }

    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_account) }

      before do
        sign_in(user)
      end

      context 'when user is authorized' do
        before do
          user.update!(brand: brand)
        end

        context 'when brand has subscription' do
          before do
            FactoryBot.create(:subscription, brand: brand)
          end

          context 'when the ticket is open' do
            before do
              ticket.update!(status: 'open')
            end

            it 'solves the ticket' do
              expect { post_invert_status }.to change { ticket.reload.status }.from('open').to('solved')
            end

            it 'sets the flash' do
              post_invert_status

              expect(controller.flash[:success]).to eq('Ticket status successfully changed.')
            end

            it 'redirects to brand tickets path' do
              post_invert_status

              expect(response).to redirect_to(brand_tickets_path(brand))
            end
          end

          context 'when the ticket is solved' do
            before do
              ticket.update!(status: 'solved')
            end

            it 'opens the ticket' do
              expect { post_invert_status }.to change { ticket.reload.status }.from('solved').to('open')
            end

            it 'sets the flash' do
              post_invert_status

              expect(controller.flash[:success]).to eq('Ticket status successfully changed.')
            end

            it 'redirects to brand tickets path' do
              post_invert_status

              expect(response).to redirect_to(brand_tickets_path(brand))
            end
          end
        end

        context 'when brand does not have subscription' do
          include_examples 'unauthorized user examples', 'You do not have an active subscription.'
        end
      end

      context 'when user is not authorized' do
        include_examples 'unauthorized user examples', 'You are not authorized.'
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthorized user examples', 'You are not authorized.'
    end
  end

  describe 'POST refresh' do
    subject(:post_refresh) { post "/brands/#{brand.id}/tickets/refresh" }

    let(:load_new_tickets_job_class) { class_spy(LoadNewTicketsJob) }

    before do
      stub_const(LoadNewTicketsJob.to_s, load_new_tickets_job_class)
    end

    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_account) }

      before do
        sign_in(user)
      end

      context 'when user is authorized' do
        before do
          brand.users << user
        end

        it 'calls the background worker' do
          post_refresh

          expect(load_new_tickets_job_class).to have_received(:perform_later)
        end

        it 'sets the flash' do
          post_refresh

          expect(controller.flash[:success]).to eq(
            'Tickets will be loaded in the background. Refresh the page to see new tickets once they load.'
          )
        end

        it 'redirects to brand tickets path' do
          post_refresh

          expect(response).to redirect_to(brand_tickets_path(brand))
        end
      end

      context 'when user is not authorized' do
        include_examples 'unauthorized user examples', 'You are not authorized.'
      end
    end

    context 'when user is not signed in' do
      include_examples 'unauthorized user examples', 'You are not authorized.'
    end
  end
end
