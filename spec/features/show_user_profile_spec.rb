require 'rails_helper'

RSpec.feature 'show user profile', type: :feature do
  let(:user) { create :user, name: 'Test user' }

  let!(:games) { [
    create(:game, id: 1000, user: user, created_at: '2022.01.01 11:00', prize: 1000, current_level: 3, fifty_fifty_used: true),
    create(:game, id: 1001, user: user, created_at: '2022.03.04 15:00', prize: 0, current_level: 0, is_failed: true, finished_at: '2021.03.04 15:05')] }

  scenario 'success' do
    visit '/'

    click_link "user_#{user.id}"

    expect(page).to have_current_path "/users/#{user.id}"

    # check user name on the page
    expect(page).to have_content 'Test user'

    # check games' statuses
    expect(page).to have_content 'fail'
    expect(page).to have_content 'in progress'

    # check games' dates
    expect(page).to have_content '04 Mar 15:00'
    expect(page).to have_content '01 Jan 11:00'

    # check games' current levels
    expect(find('#game_level_1000').text).to eq('3')
    expect(find('#game_level_1001').text).to eq('0')

    # check games' prizes
    expect(page).to have_content '$0'
    expect(page).to have_content '$1,000'

    # check 50/50 help is used
    expect(find('.game-help-used').text).to eq('50/50')

    # no edit button
    expect(page).not_to have_content 'Change name and password'
  end
end
