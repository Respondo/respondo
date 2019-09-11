# frozen_string_literal: true

RSpec.describe 'brands/tickets/index', type: :view do
  let(:brand) { FactoryBot.create(:brand) }
  let(:open_ticket) { FactoryBot.create(:ticket, status: :open) }
  let(:solved_ticket) { FactoryBot.create(:ticket, status: :solved) }

  before do
    assign(:brand, brand)
    assign(:open_tickets, [open_ticket])
    assign(:solved_tickets, [solved_ticket])
  end

  it 'renders both open and solved tickets' do
    expect(render).to render_template(partial: 'brands/tickets/_tickets', count: 2)
  end

  context 'when user is authorized' do
    before do
      allow(view).to receive(:authorized?).and_return(true)
    end

    it 'renders the refresh button' do
      expect(render).to have_button('Refresh Tickets')
    end
  end

  context 'when user is not authorized' do
    before do
      allow(view).to receive(:authorized?).and_return(false)
    end

    it 'does not render the refresh button' do
      expect(render).not_to have_button('Refresh Tickets')
    end
  end
end