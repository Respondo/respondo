# frozen_string_literal: true

RSpec.describe 'brands/tickets/index', type: :view do
  let(:brand) { FactoryBot.create(:brand) }
  let(:open_ticket) { FactoryBot.create(:ticket, status: :open) }
  let(:solved_ticket) { FactoryBot.create(:ticket, status: :solved) }

  before do
    assign(:open_tickets, [open_ticket])
    assign(:solved_tickets, [solved_ticket])

    without_partial_double_verification do
      allow(view).to receive(:brand).and_return(brand)
      allow(view).to receive(:current_user).and_return(FactoryBot.build(:user))
    end

    allow(view).to receive(:user_authorized_for?).and_return(false)
    allow(view).to receive(:user_can_reply_to?).and_return(false)
  end

  it 'renders open tickets' do
    expect(render).to include(open_ticket.content)
  end

  it 'renders solved tickets' do
    expect(render).to include(solved_ticket.content)
  end

  context 'when user is authorized' do
    before do
      allow(view).to receive(:user_authorized_for?).and_return(true)
    end

    it 'renders the refresh button' do
      expect(render).to have_button('Refresh Tickets')
    end
  end

  context 'when user is not authorized' do
    it 'does not render the refresh button' do
      expect(render).not_to have_button('Refresh Tickets')
    end
  end
end
