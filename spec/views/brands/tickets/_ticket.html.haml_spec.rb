# frozen_string_literal: true

RSpec.describe 'brands/tickets/_ticket', type: :view do
  subject(:render_ticket_partial) do
    render partial: 'brands/tickets/ticket', locals: {
      brand: brand, ticket: ticket
    }
  end

  let(:brand) { FactoryBot.create(:brand) }
  let(:user) { FactoryBot.create(:user) }
  let(:ticket) { FactoryBot.create(:ticket, brand: brand, status: :open) }
  let!(:comments) { FactoryBot.create_list(:comment, 2, ticket: ticket) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
    end

    allow(view).to receive(:user_authorized_for?).and_return(true)
    allow(view).to receive(:user_can_reply_to?).and_return(false)
  end

  it 'displays the ticket' do
    render_ticket_partial

    expect(rendered).to have_text("#{ticket.author.username}:").and have_text(ticket.content)
  end

  it 'displays provider' do
    render_ticket_partial

    expect(rendered).to have_text('Provider:', count: 1).and have_text(ticket.provider, count: 1)
  end

  it 'displays response form' do
    render_ticket_partial

    expect(rendered).to have_field(:response_text, count: 1).and have_button('Reply', count: 1)
  end

  it 'displays the status button' do
    render_ticket_partial

    expect(rendered).to have_button('Solve')
  end

  it 'displays the comment form' do
    render_ticket_partial

    expect(rendered).to have_field(:comment_text, count: 1).and have_button('Comment', count: 1)
  end

  it 'displays comments' do
    render_ticket_partial

    expect(rendered).to have_text("#{comments.first.user.name}:").and have_text(comments.first.content)
      .and have_text("#{comments.second.user.name}:").and have_text(comments.second.content)
  end

  it 'displays ticket permalink' do
    render_ticket_partial

    expect(rendered).to have_link(ticket.created_at, href: brand_ticket_path(brand, ticket))
  end

  context 'when ticket is external' do
    before do
      ticket.external!
      ticket.metadata = { response_url: 'https://google.com' }
    end

    it 'displays response form' do
      render_ticket_partial

      expect(rendered).to have_field(:response_text, count: 1).and have_button('Reply', count: 1)
    end

    it 'shows external provider for ticket' do
      render_ticket_partial

      expect(rendered).to have_text('Provider:', count: 1).and have_text('external', count: 1)
    end

    context 'when ticket has external provider' do
      before do
        ticket.metadata[:custom_provider] = 'hacker_news'
      end

      it 'shows custom external provider for ticket' do
        render_ticket_partial

        expect(rendered).to have_text('Provider:', count: 1).and have_text('hacker_news', count: 1)
      end
    end
  end

  context 'when ticket has user' do
    before do
      ticket.update(user: user)
    end

    it 'displays user along with author' do
      render_ticket_partial

      expect(rendered).to have_text("#{ticket.user.name} as #{ticket.author.username}:").and have_text(ticket.content)
    end
  end
end