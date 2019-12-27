# frozen_string_literal: true

RSpec.describe "Video Embed" do
  let(:edition) { create(:edition) }

  describe "GET /documents/:document/video-embed" do
    it "returns a bad request outside of a modal context" do
      get video_embed_path(edition.document)
      expect(response).to be_bad_request
    end

    it "is successful in a modal context" do
      get video_embed_path(edition.document),
          headers: { "Content-Publisher-Rendering-Context" => "modal" }
      expect(response).to be_successful
    end
  end

  describe "POST /documents/:document/video-embed" do
    it "returns a bad request outside of a modal context" do
      post video_embed_path(edition.document)
      expect(response).to be_bad_request
    end

    it "shows a requirement issue when an invalid video is embed" do
      post video_embed_path(edition.document),
           params: { title: nil, url: nil },
           headers: { "Content-Publisher-Rendering-Context" => "modal" }
      expect(response).to be_unprocessable
      issue = I18n.t!("requirements.video_embed_title.blank.form_message")
      expect(response.body).to include(issue)
    end

    it "returns markdown code when input is valid" do
      video_url = "https://www.youtube.com/watch?v=9haWiF6UA3Y"
      post video_embed_path(edition.document),
           params: { title: "My title", url: video_url },
           headers: { "Content-Publisher-Rendering-Context" => "modal" }
      expect(response).to be_successful
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("[My title](#{video_url})")
    end
  end
end
