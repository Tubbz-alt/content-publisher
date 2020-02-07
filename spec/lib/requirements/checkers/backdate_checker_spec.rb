# frozen_string_literal: true

RSpec.describe Requirements::Checkers::BackdateChecker do
  describe "#pre_submit_issues" do
    it "returns no issues if there are none" do
      date = Time.current.change(day: 1, month: 1, year: 2019)
      issues = Requirements::Checkers::BackdateChecker.new(date).pre_submit_issues
      expect(issues).to be_empty
    end

    it "returns an issue if the date is in the future" do
      date = 1.year.from_now
      issues = Requirements::Checkers::BackdateChecker.new(date).pre_submit_issues
      expect(issues).to have_issue(:backdate_date, :in_the_future)
    end

    it "returns an issue if the date is too long ago" do
      earliest_date = Requirements::Checkers::BackdateChecker::EARLIEST_DATE
      issues = Requirements::Checkers::BackdateChecker.new(earliest_date - 1).pre_submit_issues

      expect(issues).to have_issue(:backdate_date,
                                   :too_long_ago,
                                   date: earliest_date.strftime("%-d %B %Y"))
    end
  end
end
