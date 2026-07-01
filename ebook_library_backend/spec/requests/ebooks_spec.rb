require 'rails_helper'

RSpec.describe "Api::Ebooks", type: :request do
  def pdf_file
    Rack::Test::UploadedFile.new(
      StringIO.new("%PDF-1.4 fake pdf content"),
      "application/pdf",
      original_filename: "sample.pdf"
    )
  end

  describe "GET /api/ebooks" do
    it "returns all ebooks" do
      create_list(:ebook, 3)
      get "/api/ebooks"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end

    it "returns an empty array when no ebooks exist" do
      get "/api/ebooks"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "sorts by title when sort=title" do
      create(:ebook, title: "Zebra")
      create(:ebook, title: "Apple")
      get "/api/ebooks", params: { sort: "title" }
      titles = JSON.parse(response.body).map { |e| e["title"] }
      expect(titles).to eq(["Apple", "Zebra"])
    end
  end

  describe "POST /api/ebooks" do
    it "creates an ebook with valid params" do
      post "/api/ebooks", params: { title: "My Book", author: "Jane Doe", file: pdf_file }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["title"]).to eq("My Book")
    end

    it "fails without a title" do
      post "/api/ebooks", params: { file: pdf_file }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "fails without a file" do
      post "/api/ebooks", params: { title: "No File Book" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a non-PDF/EPUB file type" do
      txt_file = Rack::Test::UploadedFile.new(
        StringIO.new("just text"),
        "text/plain",
        original_filename: "notes.txt"
      )
      post "/api/ebooks", params: { title: "Bad Type", file: txt_file }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"].join).to match(/PDF or EPUB/)
    end

    it "rejects a file larger than the max size" do
      oversized = Rack::Test::UploadedFile.new(
        StringIO.new("a" * (Ebook::MAX_FILE_SIZE + 1)),
        "application/pdf",
        original_filename: "big.pdf"
      )
      post "/api/ebooks", params: { title: "Too Big", file: oversized }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"].join).to match(/too large/)
    end
  end

  describe "GET /api/ebooks/search" do
    it "finds ebooks by title" do
      create(:ebook, title: "Ruby Basics")
      create(:ebook, title: "Flutter in Action")
      get "/api/ebooks/search", params: { q: "Ruby" }
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["title"]).to eq("Ruby Basics")
    end

    it "returns empty array when nothing matches" do
      create(:ebook, title: "Ruby Basics")
      get "/api/ebooks/search", params: { q: "Nonexistent" }
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "GET /api/ebooks/:id/download" do
    it "redirects to the file blob" do
      ebook = create(:ebook)
      get "/api/ebooks/#{ebook.id}/download"
      expect(response).to have_http_status(:redirect)
    end

    it "returns 404 for a missing ebook" do
      get "/api/ebooks/999999/download"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/ebooks/:id" do
    it "deletes the ebook" do
      ebook = create(:ebook)
      expect { delete "/api/ebooks/#{ebook.id}" }.to change(Ebook, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 when deleting a non-existent ebook" do
      delete "/api/ebooks/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end