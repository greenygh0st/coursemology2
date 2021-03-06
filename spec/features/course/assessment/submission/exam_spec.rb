# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Course: Assessment: Submissions: Exam' do
  let(:instance) { Instance.default }

  with_tenant(:instance) do
    let(:course) { create(:course) }
    let(:assessment) do
      create(:assessment, :exam, :published_with_mrq_question, course: course)
    end
    let(:mrq_questions) { assessment.reload.questions.map(&:specific) }
    let(:student) { create(:course_student, course: course).user }
    let(:submission) do
      create(:submission, assessment: assessment, creator: student)
    end

    before { login_as(user, scope: :user) }

    context 'As a Course Student' do
      let(:user) { student }

      scenario 'I need to input the password before attempting exams', js: true do
        assessment
        visit course_assessments_path(course)

        within find(content_tag_selector(assessment)) do
          find_link(
            I18n.t('course.assessment.assessments.assessment_management_buttons.attempt')
          ).trigger('click')
        end
        expect(page).to have_selector('div.password-panel')

        fill_in 'session_password', with: 'wrong_password'
        click_button I18n.t('course.assessment.sessions.new.continue')
        expect(current_path).to eq(new_course_assessment_session_path(course, assessment))

        fill_in 'session_password', with: assessment.password
        click_button I18n.t('course.assessment.sessions.new.continue')

        # The user should be redirect to submission edit page
        expect(page).to have_selector('h1', text: assessment.title)
      end

      scenario 'I can edit and save my submission', js: true do
        submission
        visit edit_course_assessment_submission_path(course, assessment, submission)

        fill_in 'session_password', with: assessment.password
        click_button I18n.t('course.assessment.sessions.new.continue')
        expect(page).to have_selector('h1', text: assessment.title)

        option = assessment.questions.first.actable.options.first.option
        check option
        click_button I18n.t('common.save')

        expect(current_path).to eq(
          edit_course_assessment_submission_path(course, assessment, submission)
        )
        expect(page).to have_checked_field(option)
      end
    end

    context 'As a Course Staff' do
      let(:user) { create(:course_teaching_assistant, course: course).user }

      scenario 'I can submit the grading for publishing' do
        mrq_questions.each { |q| q.attempt(submission).save! }
        submission.finalise!
        submission.save!

        visit edit_course_assessment_submission_path(course, assessment, submission)

        expect(page).to have_button(I18n.t('common.save'))

        click_button I18n.t('course.assessment.submission.submissions.buttons.mark')
        expect(current_path).
          to eq(edit_course_assessment_submission_path(course, assessment, submission))
        expect(submission.reload.graded?).to be_truthy
      end
    end
  end
end
