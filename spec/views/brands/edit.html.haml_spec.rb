# frozen_string_literal: true

RSpec.describe 'brands/edit', type: :view do
  let(:brand) { FactoryBot.create(:brand) }
  let!(:user_in_brand) { FactoryBot.create(:user) }
  let!(:user_outside_brand) { FactoryBot.create(:user) }

  before do
    brand.users << user_in_brand

    assign(:brand, brand)
  end

  it 'renders all users' do
    expect(render).to have_text(user_in_brand.name)
  end

  it 'has the add user select box' do
    expect(render).to have_select('add-user', options: [user_outside_brand.name])
  end

  it 'has the remove user select box' do
    expect(render).to have_select('remove-user', options: [user_in_brand.name])
  end
end