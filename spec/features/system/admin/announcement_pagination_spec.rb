require 'rails_helper'

RSpec.describe 'System: Administration: Announcements', type: :feature do
  describe 'Pagination' do
    subject { page }

    let!(:user) { create(:administrator) }

    before do
      System::Announcement.delete_all
      create_list(:system_announcement, 50, creator: user, updater: user)

      login_as(user, scope: :user)
      visit admin_announcements_path
    end

    it { is_expected.to have_selector('nav.pagination') }

    it 'lists each announcement' do
      System::Announcement.page(1).each do |announcement|
        expect(page).to have_selector('div', text: announcement.title)
        expect(page).to have_selector('div', text: announcement.content)
      end
    end

    context 'after clicked second page' do
      before { visit admin_announcements_path(page: '2') }

      it 'lists each announcement' do
        System::Announcement.page(2).each do |announcement|
          expect(page).to have_selector('div', text: announcement.title)
          expect(page).to have_selector('div', text: announcement.content)
        end
      end
    end
  end
end
