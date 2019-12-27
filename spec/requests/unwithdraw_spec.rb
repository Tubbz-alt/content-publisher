# frozen_string_literal: true

RSpec.describe "Unwithdraw" do
  let(:managing_editor) { create(:user, managing_editor: true) }

  it_behaves_like "requests that assert edition state",
                  "unwithdrawing a non withdrawn edition",
                  routes: { unwithdraw_path: %i[get post] } do
    before { login_as(managing_editor) }
    let(:edition) { create(:edition, :published) }
  end

  describe "GET /documents/:document/unwithdraw" do
    let(:edition) { create(:edition, :withdrawn) }

    context "when logged in as a managing editor" do
      let(:managing_editor) { create(:user, managing_editor: true) }
      before { login_as(managing_editor) }

      it "redirects to document summary to confirm" do
        get unwithdraw_path(edition.document)
        expect(response).to redirect_to(document_path(edition.document))
        follow_redirect!
        expect(response.body)
          .to include(I18n.t!("documents.show.unwithdraw.description"))
      end
    end

    context "when not logged in as a managing editor" do
      it "returns a forbidden response" do
        get unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body)
          .to include(I18n.t!("unwithdraw.no_managing_editor_permission.title"))
      end
    end

    context "when edition is history mode" do
      let(:edition) do
        create(:edition, :withdrawn, :political, government: past_government)
      end

      it "allows a managing editor with the manage_live_history_mode permission to confirm" do
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)
        get unwithdraw_path(edition.document)
        expect(response).to be_redirect
      end

      it "prevents a managing editor without the manage_live_history_mode permission from confirming" do
        user = create(:user, managing_editor: true, manage_live_history_mode: false)
        login_as(user)
        get unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body).to include(
          I18n.t!("missing_permissions.update_history_mode.title", title: edition.title),
        )
      end

      it "prevents a regular user from confirming" do
        get unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body).to include(
          I18n.t!("missing_permissions.update_history_mode.title", title: edition.title),
        )
      end

      it "prevents a regular user with the manage_live_history_mode permission from confirming" do
        user = create(:user, manage_live_history_mode: true)
        login_as(user)
        get unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body)
          .to include(I18n.t!("unwithdraw.no_managing_editor_permission.title"))
      end
    end
  end

  describe "POST /documents/:document/unwithdraw" do
    let(:edition) { create(:edition, :withdrawn) }
    before { stub_publishing_api_republish(edition.content_id, {}) }

    context "when logged in as a managing editor" do
      let(:managing_editor) { create(:user, managing_editor: true) }
      before { login_as(managing_editor) }

      it "unwithdraws and redirects to document summary" do
        post unwithdraw_path(edition.document)
        expect(response).to redirect_to(document_path(edition.document))
        follow_redirect!
        expect(response.body).to have_tag(".app-c-metadata") do
          with_text(I18n.t!("user_facing_states.published.name"))
        end
      end

      it "redirects to document summary with an error when Publishing API is down" do
        publishing_api_isnt_available

        post unwithdraw_path(edition.document)
        expect(response).to redirect_to(document_path(edition.document))
        follow_redirect!
        expect(response.body).to include(
          I18n.t!("documents.show.flashes.unwithdraw_error.title"),
        )
      end
    end

    context "when not logged in as a managing editor" do
      it "returns a forbidden response" do
        post unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body)
          .to include(I18n.t!("unwithdraw.no_managing_editor_permission.title"))
      end
    end

    context "when edition is history mode" do
      let(:edition) do
        create(:edition, :withdrawn, :political, government: past_government)
      end

      it "allows a managing editor with the manage_live_history_mode permission to unwithdraw" do
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)
        post unwithdraw_path(edition.document)
        expect(response).to be_redirect
      end

      it "prevents a managing editor without the manage_live_history_mode permission from unwithdrawing" do
        user = create(:user, managing_editor: true, manage_live_history_mode: false)
        login_as(user)
        post unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body).to include(
          I18n.t!("missing_permissions.update_history_mode.title", title: edition.title),
        )
      end

      it "prevents a regular user from unwithdrawing" do
        post unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body).to include(
          I18n.t!("missing_permissions.update_history_mode.title", title: edition.title),
        )
      end

      it "prevents a regular user with the manage_live_history_mode permission from unwithdrawing" do
        user = create(:user, manage_live_history_mode: true)
        login_as(user)
        post unwithdraw_path(edition.document)
        expect(response).to be_forbidden
        expect(response.body)
          .to include(I18n.t!("unwithdraw.no_managing_editor_permission.title"))
      end
    end
  end
end
