RSpec.describe WhitehallImporter::IntegrityChecker::BodyTextCheck do
  it "retuns no problems if the proposed payload matches" do
    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new("Some text", "Some text")
    expect(integrity_check.sufficiently_similar?).to be true
  end

  it "does not return a problem when the body text whitespace does not match" do
    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new("Some text", "Some     text")
    expect(integrity_check.sufficiently_similar?).to be true
  end

  it "does not return a problem when the HTML does not match" do
    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new("<b>Some text</b>", "Some text")
  end

  it "returns no problems even if there is a mismatch in inline atttachment URL filesize" do
    proposed_body = %(
      <p>
        <span class="gem-c-attachment-link">
          <a class="govuk-link" href="filename.pdf" target="_blank">Test File</a>
          (<span class="gem-c-attachment-link__attribute"><abbr title="Portable Document Format" class="gem-c-attachment-link__abbr">PDF</abbr></span>,
            <span class="gem-c-attachment-link__attribute">391 KB</span>, <span class="gem-c-attachment-link__attribute">9 pages</span>)
        </span>
      </p>
    )

    publishing_api_body = %(
      <p>
        <span class="attachment-inline">
          <a href="/filename.pdf">Test File</a>
          (<span class="type">PDF</span>,
            <span class="file-size">391KB</span>,
            <span class="page-length">9 pages</span>)
        </span>
      </p>
    )

    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new(proposed_body, publishing_api_body)
    expect(integrity_check.sufficiently_similar?).to be true
  end

  it "returns a problem when the body text doesn't match" do
    integrity_check = WhitehallImporter::IntegrityChecker::BodyTextCheck.new("Some text", "Some different text")
    expect(integrity_check.sufficiently_similar?).to be false
  end
end
