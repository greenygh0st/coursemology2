# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Course: Assessments: Questions: Text Response Management' do
  let(:instance) { Instance.default }

  with_tenant(:instance) do
    let(:course) { create(:course) }
    let(:assessment) { create(:assessment, course: course) }
    before { login_as(user, scope: :user) }

    context 'As a Course Manager' do
      let(:user) { create(:course_manager, course: course).user }

      scenario 'I can create a new text response question' do
        skill = create(:course_assessment_skill, course: course)
        visit course_assessment_path(course, assessment)
        click_link I18n.t('course.assessment.assessments.show.new_question.text_response')

        expect(current_path).to eq(
          new_course_assessment_question_text_response_path(course, assessment)
        )
        question_attributes = attributes_for(:course_assessment_question_text_response)
        fill_in 'title', with: question_attributes[:title]
        fill_in 'description', with: question_attributes[:description]
        fill_in 'staff_only_comments', with: question_attributes[:staff_only_comments]
        fill_in 'maximum_grade', with: question_attributes[:maximum_grade]
        fill_in 'weight', with: question_attributes[:weight]
        check 'question_text_response_allow_attachment'
        within find_field('skills') do
          select skill.title
        end
        click_button I18n.t('helpers.buttons.create')

        question_created = assessment.questions.first.specific
        expect(page).to have_content_tag_for(question_created)
        expect(question_created.skills).to contain_exactly(skill)
        expect(question_created.weight).to eq(question_attributes[:weight])
        expect(question_created.allow_attachment).to be_truthy
      end

      scenario 'I can create a new file upload question' do
        visit course_assessment_path(course, assessment)
        click_link I18n.t('course.assessment.assessments.show.new_question.file_upload')

        file_upload_path = new_course_assessment_question_text_response_path(course, assessment)
        expect(current_path).to eq(file_upload_path)

        question_attributes = attributes_for(:course_assessment_question_text_response)
        fill_in 'title', with: question_attributes[:title]
        fill_in 'description', with: question_attributes[:description]
        fill_in 'staff_only_comments', with: question_attributes[:staff_only_comments]
        fill_in 'maximum_grade', with: question_attributes[:maximum_grade]
        fill_in 'weight', with: question_attributes[:weight]
        click_button I18n.t('helpers.buttons.create')

        question_created = assessment.questions.first.specific
        expect(page).to have_content_tag_for(question_created)
        expect(question_created.hide_text).to be_truthy
        expect(question_created.allow_attachment).to be_truthy
      end

      scenario 'I can edit a text response question', js: true do
        question = create(:course_assessment_question_text_response, assessment: assessment,
                                                                     solutions: [])
        solutions = [
          attributes_for(:course_assessment_question_text_response_solution, :keyword),
          attributes_for(:course_assessment_question_text_response_solution, :exact_match)
        ]
        visit course_assessment_path(course, assessment)

        edit_path = edit_course_assessment_question_text_response_path(course, assessment, question)
        find_link(nil, href: edit_path).click

        maximum_grade = 999.9
        fill_in 'maximum_grade', with: maximum_grade
        click_button I18n.t('helpers.buttons.update')

        expect(current_path).to eq(course_assessment_path(course, assessment))
        expect(question.reload.maximum_grade).to eq(maximum_grade)

        visit edit_path

        solutions.each_with_index do |solution, i|
          link = I18n.t('course.assessment.question.text_responses.form.add_solution')
          find('a.add_fields', text: link).trigger('click')
          within all('.edit_question_text_response '\
            'tr.question_text_response_solution')[i] do
            find('textarea.text-response-solution').set solution[:solution]
            find('textarea.text-response-explanation').set solution[:explanation]
            solution_type = find('select.text-response-solution-type', visible: :all)
            # Twitter Bootstrap hides <select> element and creates a div.
            # The usual #select method is broken as it does not seem to work with hidden elements.
            if solution[:exact_match]
              solution_type.find('option[value="exact_match"]', visible: :all).select_option
            else
              solution_type.find('option[value="keyword"]', visible: :all).select_option
            end
          end
        end
        click_button I18n.t('helpers.buttons.update')
        expect(current_path).to eq(course_assessment_path(course, assessment))
        expect(page).to have_selector('div.alert.alert-success')
      end

      scenario 'I can delete a text response question' do
        question = create(:course_assessment_question_text_response, assessment: assessment)
        visit course_assessment_path(course, assessment)

        delete_path = course_assessment_question_text_response_path(course, assessment, question)
        find_link(nil, href: delete_path).click

        expect(current_path).to eq(course_assessment_path(course, assessment))
        expect(page).not_to have_content_tag_for(question)
      end
    end

    context 'As a Student' do
      let(:user) { create(:course_user, :approved, course: course).user }

      scenario 'I cannot add questions' do
        visit new_course_assessment_question_text_response_path(course, assessment)

        expect(page.status_code).to eq(403)
      end
    end
  end
end
