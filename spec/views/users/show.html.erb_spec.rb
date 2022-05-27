require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { build_stubbed(:user, id: 20, name: 'Sam') }
  before do
    assign(:user, user)

    view.stub(:current_user) { current_user }

    assign(:games, [build_stubbed(:game)])
    stub_template('users/_game.html.erb' => 'User game')

    render
  end

  context 'when current user is the user' do
    let!(:current_user) { user }

    it 'renders user name' do
      expect(rendered).to match 'Sam'
    end

    it 'renders edit button' do
      expect(rendered).to include t('views.users.show.change_credentials')
    end

    it 'renders game partial' do
      expect(rendered).to have_content 'User game'
    end
  end

  context 'when current user is not the user' do
    let!(:current_user) { build_stubbed(:user, id: 10, name: 'Tim') }

    it 'renders user name' do
      expect(rendered).to match 'Sam'
    end

    it 'does not render edit button' do
      expect(rendered).not_to include t('views.users.show.change_credentials')
    end

    it 'renders game partial' do
      expect(rendered).to have_content 'User game'
    end
  end

  context 'when current user is nil' do
    let!(:current_user) { nil }

    it 'renders user name' do
      expect(rendered).to match 'Sam'
    end

    it 'does not render edit button' do
      expect(rendered).not_to include t('views.users.show.change_credentials')
    end

    it 'renders game partial' do
      expect(rendered).to have_content 'User game'
    end
  end
end