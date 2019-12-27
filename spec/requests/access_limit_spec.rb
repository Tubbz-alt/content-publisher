# frozen_string_literal: true

RSpec.describe "Access Limit" do
  let(:document_type) do
    organisation = build(:tag_field,
                         type: "single_tag",
                         id: "primary_publishing_organisation")
    build(:document_type, tags: [organisation])
  end

  let(:organisation_id) { current_user.organisation_content_id }

  before do
    stub_publishing_api_has_linkables(
      [{ "content_id" => organisation_id, "internal_name" => "Primary org" }],
      document_type: "organisation",
    )
  end

  it_behaves_like "requests that assert edition state",
                  "access limiting a non editable edition",
                  routes: { access_limit_path: %i[get patch] } do
    let(:edition) { create(:edition, :published) }
  end

  describe "GET /documents/:document/acces-limit" do
    let(:edition) do
      create(:edition,
             document_type_id: document_type.id,
             tags: { primary_publishing_organisation: [organisation_id],
                     organisations: [organisation_id] })
    end

    it "returns a successful response" do
      get access_limit_path(edition.document)

      expect(response).to be_successful
    end

    it "returns a service unavailable response when the Publishing API is down" do
      stub_publishing_api_isnt_available
      get access_limit_path(edition.document)

      expect(response.status).to eq(503)
      expect(response.body).to include(I18n.t!("access_limit.edit.api_down"))
    end
  end

  describe "PATCH /documents/:document/access-limit" do
    before { stub_any_publishing_api_put_content }

    let(:edition) do
      create(:edition,
             document_type_id: document_type.id,
             tags: { primary_publishing_organisation: [organisation_id],
                     organisations: [organisation_id] })
    end

    it "redirects to the document summary" do
      patch access_limit_path(edition.document),
            params: { limit_type: "primary_organisation" }

      expect(response).to redirect_to(document_path(edition.document))
    end

    it "returns unprocessable with the issue when there are requirement issues" do
      user_without_organisation = create(:user, organisation_content_id: nil)
      login_as(user_without_organisation)
      patch access_limit_path(edition.document),
            params: { limit_type: "primary_organisation" }

      expect(response).to be_unprocessable
      expect(response.body).to include(
        I18n.t!("requirements.access_limit.user_has_no_org.form_message"),
      )
    end
  end
end
