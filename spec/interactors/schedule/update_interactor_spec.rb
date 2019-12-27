# frozen_string_literal: true

RSpec.describe Schedule::UpdateInteractor do
  describe ".call" do
    before { stub_any_publishing_api_put_intent }

    let(:scheduling) { build(:scheduling) }
    let(:edition) { create(:edition, :scheduled, scheduling: scheduling) }
    let(:user) { build(:user) }
    let(:publish_time) { 3.weeks.from_now.beginning_of_day }

    def build_params(document: edition.document, time: publish_time)
      ActionController::Parameters.new(
        document: document.to_param,
        schedule: {
          time: time.strftime("%-l:%M%P"),
          date: {
            day: time.day,
            month: time.month,
            year: time.year,
          },
        },
      )
    end

    it "delegates to ScheduleService to schedule the edition for publishing" do
      expect(ScheduleService)
        .to receive(:call) do |schedule_edition, schedule_user, new_scheduling|
          expect(schedule_edition).to eq(edition)
          expect(schedule_user).to eq(user)
          expect(new_scheduling.reviewed).to eq(scheduling.reviewed)
          expect(new_scheduling.publish_time).to eq(publish_time)
        end

      Schedule::UpdateInteractor.call(params: build_params, user: user)
    end

    it "creates a timeline entry" do
      expect { Schedule::UpdateInteractor.call(params: build_params, user: user) }
        .to change { TimelineEntry.where(entry_type: :schedule_updated).count }
        .by(1)
    end

    it "returns a success with edition and publish time" do
      result = Schedule::UpdateInteractor.call(params: build_params, user: user)

      expect(result).to be_success
      expect(result.edition).to eq(edition)
      expect(result.publish_time).to eq(publish_time)
    end

    context "when the scheduling is the same as scheduled time" do
      let(:scheduling) { build(:scheduling, publish_time: publish_time) }
      let(:params) { build_params(time: publish_time) }

      it "fails without scheduling the edition" do
        expect(ScheduleService).not_to receive(:call)
        result = Schedule::UpdateInteractor.call(params: params, user: user)
        expect(result).to be_failure
      end

      it "doesn't create a timeline entry" do
        expect { Schedule::UpdateInteractor.call(params: params, user: user) }
          .not_to(change { TimelineEntry.where(entry_type: :schedule_updated).count })
      end
    end

    it "raises an error when the edition isn't scheduled" do
      params = build_params(document: create(:document, :with_current_edition))
      expect { Schedule::UpdateInteractor.call(params: params, user: user) }
        .to raise_error(EditionAssertions::StateError)
    end

    it "fails with issues when date and time can't be parsed" do
      params = build_params
      params[:schedule][:time] = "invalid"

      result = Schedule::UpdateInteractor.call(params: params, user: user)
      expect(result).to be_failure
      expect(result.issues).to have_issue(:schedule_time, :invalid)
    end

    it "fails with issues when the time fails the publish time requirements" do
      params = build_params(time: Time.zone.yesterday)

      result = Schedule::UpdateInteractor.call(params: params, user: user)
      expect(result).to be_failure
      expect(result.issues).to have_issue(:schedule_date, :in_the_past)
    end

    it "fails with an API error when ScheduleService raises a GdsApi Error" do
      stub_publishing_api_isnt_available
      result = Schedule::UpdateInteractor.call(params: build_params, user: user)

      expect(result).to be_failure
      expect(result.api_error).to be(true)
    end
  end
end
