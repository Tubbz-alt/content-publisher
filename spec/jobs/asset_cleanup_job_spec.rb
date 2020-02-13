RSpec.describe AssetCleanupJob do
  describe "#perform" do
    let(:draft_image_revision) { create(:image_revision, :on_asset_manager, state: :draft) }
    let(:live_image_revision) { create(:image_revision, :on_asset_manager, state: :live) }
    let(:draft_file_attachment_revision) { create(:file_attachment_revision, :on_asset_manager, state: :draft) }
    let(:live_file_attachment_revision) { create(:file_attachment_revision, :on_asset_manager, state: :live) }

    context "when the assets only exist on a past edition" do
      before do
        create(:edition,
               current: false,
               lead_image_revision: nil,
               image_revisions: [draft_image_revision, live_image_revision],
               file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])
      end

      it "deletes draft/live assets that are dangling" do
        request = stub_asset_manager_deletes_any_asset
        described_class.perform_now

        expect(request).to have_been_requested.at_least_once
        expect(draft_image_revision.reload.assets.map(&:state).uniq).to eq(%w[absent])
        expect(draft_file_attachment_revision.reload.asset).to be_absent
        expect(live_image_revision.reload.assets.map(&:state).uniq).to eq(%w[absent])
        expect(live_file_attachment_revision.reload.asset).to be_absent
      end
    end

    context "when the assets only exist on a previous revision" do
      before do
        preceding_revision = create(:revision,
                                    lead_image_revision: nil,
                                    image_revisions: [draft_image_revision, live_image_revision],
                                    file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])

        revision = create(:revision, lead_image_revision: nil, preceded_by: preceding_revision)
        create(:edition, revision: revision)
      end

      it "deletes draft/live assets that are dangling" do
        request = stub_asset_manager_deletes_any_asset
        described_class.perform_now

        expect(request).to have_been_requested.at_least_once
        expect(draft_image_revision.reload.assets.map(&:state).uniq).to eq(%w[absent])
        expect(draft_file_attachment_revision.reload.asset).to be_absent
        expect(live_image_revision.reload.assets.map(&:state).uniq).to eq(%w[absent])
        expect(live_file_attachment_revision.reload.asset).to be_absent
      end
    end

    context "when the assets exist on a current edition" do
      before do
        create(:edition,
               lead_image_revision: nil,
               image_revisions: [draft_image_revision, live_image_revision],
               file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])
      end

      it "preserves draft/live assets in Asset Manager" do
        request = stub_asset_manager_deletes_any_asset
        described_class.perform_now

        expect(request).not_to have_been_requested
        expect(draft_image_revision.reload.assets.map(&:state).uniq).to eq(%w[draft])
        expect(draft_file_attachment_revision.reload.asset).to be_draft
        expect(live_image_revision.reload.assets.map(&:state).uniq).to eq(%w[live])
        expect(live_file_attachment_revision.reload.asset).to be_live
      end
    end

    context "when the assets exist on a live edition" do
      before do
        create(:edition,
               live: true,
               current: false,
               lead_image_revision: nil,
               image_revisions: [draft_image_revision, live_image_revision],
               file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])
      end

      it "preserves draft/live assets in Asset Manager" do
        request = stub_asset_manager_deletes_any_asset
        described_class.perform_now

        expect(request).not_to have_been_requested
        expect(draft_image_revision.reload.assets.map(&:state).uniq).to eq(%w[draft])
        expect(draft_file_attachment_revision.reload.asset).to be_draft
        expect(live_image_revision.reload.assets.map(&:state).uniq).to eq(%w[live])
        expect(live_file_attachment_revision.reload.asset).to be_live
      end
    end

    context "when the assets from the current revision also exist on a past revision" do
      before do
        preceding_revision = create(:revision,
                                    lead_image_revision: nil,
                                    image_revisions: [draft_image_revision, live_image_revision],
                                    file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])

        revision = create(:revision,
                          lead_image_revision: nil,
                          preceded_by: preceding_revision,
                          image_revisions: [draft_image_revision, live_image_revision],
                          file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])

        create(:edition, revision: revision)
      end

      it "doesn't delete the assets" do
        request = stub_asset_manager_deletes_any_asset
        described_class.perform_now

        expect(request).not_to have_been_requested
        expect(draft_image_revision.reload.assets.map(&:state).uniq).to eq(%w[draft])
        expect(draft_file_attachment_revision.reload.asset).to be_draft
        expect(live_image_revision.reload.assets.map(&:state).uniq).to eq(%w[live])
        expect(live_file_attachment_revision.reload.asset).to be_live
      end
    end

    context "when the assets exist on a past edition and the current edition" do
      before do
        create(:edition,
               current: false,
               lead_image_revision: nil,
               image_revisions: [draft_image_revision, live_image_revision],
               file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])

        create(:edition,
               lead_image_revision: nil,
               image_revisions: [draft_image_revision, live_image_revision],
               file_attachment_revisions: [draft_file_attachment_revision, live_file_attachment_revision])
      end

      it "doesn't delete the assets" do
        request = stub_asset_manager_deletes_any_asset
        described_class.perform_now

        expect(request).not_to have_been_requested
        expect(draft_image_revision.reload.assets.map(&:state).uniq).to eq(%w[draft])
        expect(draft_file_attachment_revision.reload.asset).to be_draft
        expect(live_image_revision.reload.assets.map(&:state).uniq).to eq(%w[live])
        expect(live_file_attachment_revision.reload.asset).to be_live
      end
    end
  end
end
