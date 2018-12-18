# frozen_string_literal: true

RSpec.describe Requirements::ImageChecker do
  describe "#pre_preview_issues" do
    it "returns no issues if there are none" do
      image = build :image, alt_text: "something"
      issues = Requirements::ImageChecker.new(image).pre_preview_issues
      expect(issues.items).to be_empty
    end

    it "returns an issue if there is no alt text" do
      image = build :image
      issues = Requirements::ImageChecker.new(image).pre_preview_issues

      form_message = issues.items_for(:alt_text).first[:text]
      expect(form_message).to eq(I18n.t!("requirements.alt_text.blank.form_message"))

      summary_message = issues.items_for(:alt_text, style: "summary").first[:text]
      expect(summary_message).to eq(I18n.t!("requirements.alt_text.blank.summary_message", filename: image.filename))
    end

    it "returns an issue if the alt text is too long" do
      max_length = Requirements::ImageChecker::ALT_TEXT_MAX_LENGTH
      image = build :image, alt_text: "a" * (max_length + 1)
      issues = Requirements::ImageChecker.new(image).pre_preview_issues

      form_message = issues.items_for(:alt_text).first[:text]
      expect(form_message).to eq(I18n.t!("requirements.alt_text.too_long.form_message", max_length: max_length))

      summary_message = issues.items_for(:alt_text, style: "summary").first[:text]
      expect(summary_message).to eq(I18n.t!("requirements.alt_text.too_long.summary_message", max_length: max_length, filename: image.filename))
    end

    it "returns an issue if the caption is too long" do
      max_length = Requirements::ImageChecker::CAPTION_MAX_LENGTH
      image = build :image, caption: "a" * (max_length + 1)
      issues = Requirements::ImageChecker.new(image).pre_preview_issues

      form_message = issues.items_for(:caption).first[:text]
      expect(form_message).to eq(I18n.t!("requirements.caption.too_long.form_message", max_length: max_length))

      summary_message = issues.items_for(:caption, style: "summary").first[:text]
      expect(summary_message).to eq(I18n.t!("requirements.caption.too_long.summary_message", max_length: max_length, filename: image.filename))
    end

    it "returns an issue if the credit is too long" do
      max_length = Requirements::ImageChecker::CREDIT_MAX_LENGTH
      image = build(:image, credit: "a" * (max_length + 1))
      issues = Requirements::ImageChecker.new(image).pre_preview_issues

      form_message = issues.items_for(:credit).first[:text]
      expect(form_message).to eq(I18n.t!("requirements.credit.too_long.form_message", max_length: max_length))

      summary_message = issues.items_for(:credit, style: "summary").first[:text]
      expect(summary_message).to eq(I18n.t!("requirements.credit.too_long.summary_message", max_length: max_length, filename: image.filename))
    end
  end
end
