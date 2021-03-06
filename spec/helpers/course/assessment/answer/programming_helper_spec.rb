require 'rails_helper'

RSpec.describe Course::Assessment::Answer::ProgrammingHelper do
  let(:instance) { Instance.default }
  with_tenant(:instance) do
    describe '#format_programming_answer_file' do
      let(:language) { Coursemology::Polyglot::Language::Python::Python2Point7 }
      let(:snippet) do
        <<-PYTHON
          def hello:
            pass
        PYTHON
      end
      let(:helper) do
        super().tap do |helper|
          helper.extend(ApplicationFormattersHelper)
        end
      end

      before { controller.define_singleton_method(:current_user) { nil } }
      subject { helper.format_programming_answer_file(file, language) }

      context 'when given a file with no annotations' do
        let(:file) do
          build(:course_assessment_answer_programming_file, answer: nil, content: snippet)
        end

        it 'syntax highlights the file' do
          expect(subject).to have_tag('span.k', text: 'def')
        end
      end

      context 'when annotations are present' do
        let(:file) do
          build(:course_assessment_answer_programming_file, content: snippet)
        end
        let(:annotation) do
          build(:course_assessment_answer_programming_file_annotation,
                file: nil, line: 1) do |annotation|
            file.annotations << annotation
          end
        end
        let!(:posts) do
          create_list(:course_discussion_post, 3, topic: annotation.discussion_topic).tap do |posts|
            annotation.discussion_topic.posts.concat(posts)
          end
        end

        it 'creates the annotation cell' do
          expect(subject).to have_tag("td.line-annotation[data-line-number='#{annotation.line}']",
                                      count: 1)
        end

        it 'creates the discussion thread' do
          expect(subject).to have_tag('td.line-annotation div.discussion_post',
                                      count: annotation.discussion_topic.posts.count)
        end
      end
    end

    describe '#get_output' do
      let(:test_result) do
        build_stubbed(:course_assessment_answer_programming_auto_grading_test_result,
                      test_result_trait)
      end
      subject { get_output(test_result) }

      context 'when there are no messages' do
        let(:test_result_trait) {}

        it { is_expected.to eq('') }
      end

      context 'when test failed' do
        let(:test_result_trait) { :failed }

        it { is_expected.to eq(test_result.messages['failure']) }
      end

      context 'when test errored' do
        let(:test_result_trait) { :errored }

        it { is_expected.to eq(test_result.messages['error']) }
      end

      context 'when output attribute is set' do
        let(:test_result_trait) { :output }

        it { is_expected.to eq(test_result.messages['output']) }
      end

      context 'when both output and failure messages are present' do
        let(:test_result_trait) { :failed_with_output }

        it { is_expected.to eq(test_result.messages['output']) }
      end
    end
  end
end
