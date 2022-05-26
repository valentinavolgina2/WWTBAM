require 'rails_helper'

RSpec.describe 'users/_game', type: :view do
  let(:game) do
    build_stubbed(
      :game, id: 15, created_at: Time.parse('2016.10.09, 12:00'), current_level: 10, prize: 1000
    )
  end

  before do
    allow(game).to receive(:status).and_return(:in_progress)

    render partial: 'users/game', object: game
  end

  it 'renders game id' do
    expect(rendered).to match '15'
  end

  it 'renders game start time' do
    created_at = Time.parse('2016.10.09, 12:00')
    expect(rendered).to include l created_at, format: :short
  end

  it 'renders game current question' do
    expect(rendered).to match '10'
  end

  it 'renders game status' do
    expect(rendered).to include t("game_statuses.#{:in_progress}")
  end

  it 'renders game prize' do
    expect(rendered).to include number_to_currency(1000)
  end
end