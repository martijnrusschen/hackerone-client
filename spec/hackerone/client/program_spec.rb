require "spec_helper"

RSpec.describe HackerOne::Client::Program do
  let(:api) { HackerOne::Client::Api.new("github") }

  before(:all) do
    ENV["HACKERONE_TOKEN_NAME"] = "foo"
    ENV["HACKERONE_TOKEN"] = "bar"
  end

  let(:program) do
    VCR.use_cassette(:programs) do
      described_class.find "github"
    end
  end

  describe 'find' do
    it "returns a team as object when provided the handle" do
      expect(program.id).to eq("18969")
      expect(program.handle).to eq("github")
    end
  end

  describe 'common responses' do
    it "returns the common responses of the program" do
      expect(
        VCR.use_cassette(:common_responses) do
          program.common_responses
        end
      ).to be_present
    end
  end

  describe '.incremental_activities' do
    it 'can traverse through the activities of a program' do
      incremental_activities = program.incremental_activities(updated_at_after: DateTime.new(2018, 12, 4, 15, 38), page_size: 3)

      activities = []
      VCR.use_cassette(:traverse_through_3_activities) do
        incremental_activities.traverse do |activity|
          activities << activity
        end
      end

      expect(activities.size).to eq 3
      bug_resolved, reference_added, bug_filed = activities

      expect(bug_resolved)
        .to be_a HackerOne::Client::Activities::BugResolved
      expect(bug_resolved.message).to be_present
      expect(bug_resolved.message).to eq 'Sent it.'
      expect(reference_added)
        .to be_a HackerOne::Client::Activities::ReferenceIdAdded
      expect(reference_added.reference).to eq 'T1722'
      expect(bug_filed)
        .to be_a HackerOne::Client::Activities::BugFiled
      expect(bug_filed.report_id).to eq '458533'
    end

    it 'can traverse through all activities of a program' do
      incremental_activities = program.incremental_activities

      activities = []
      VCR.use_cassette(:traverse_through_all_activities) do
        incremental_activities.traverse do |activity|
          activities << activity
        end
      end

      expect(activities.size).to eq 25

      # Assert no activity appears twice
      name_and_updated_at = activities.map do |activity|
        "#{activity.class} #{activity.updated_at}"
      end
      expect(name_and_updated_at.size).to eq name_and_updated_at.uniq.size
    end
  end
end
