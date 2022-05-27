require 'rails_helper'

RSpec.feature 'USER creates game', type: :feature do
  let(:user) { create :user }

  let!(:questions) do
    (0..14).to_a.map do |i|
      create(
        :question, level: i,
        text: "Question number #{i}?",
        answer1: '1', answer2: '2', answer3: '3', answer4: '4'
      )
    end
  end

  before do
    login_as user
  end

  scenario 'success' do
    visit '/'

    click_link 'New game'

    expect(page).to have_current_path '/games/1'

    expect(page).to have_content 'Question number 0?'

    expect(page).to have_content '1'
    expect(page).to have_content '2'
    expect(page).to have_content '3'
    expect(page).to have_content '4'

    # save_and_open_page
  end
end
