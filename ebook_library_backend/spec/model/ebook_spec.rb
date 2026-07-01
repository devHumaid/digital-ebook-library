require 'rails_helper'

RSpec.describe Ebook, type: :model do
  it "is valid with a title and an attached file" do
    ebook = build(:ebook)
    expect(ebook).to be_valid
  end

  it "is invalid without a title" do
    ebook = build(:ebook, title: nil)
    expect(ebook).not_to be_valid
    expect(ebook.errors[:title]).to include("can't be blank")
  end

  it "is invalid without a file" do
    ebook = Ebook.new(title: "No File")
    expect(ebook).not_to be_valid
    expect(ebook.errors[:file]).to include("can't be blank")
  end

  it "rejects a disallowed file type" do
    ebook = build(:ebook)
    ebook.file.attach(
      io: StringIO.new("just text"),
      filename: "notes.txt",
      content_type: "text/plain"
    )
    expect(ebook).not_to be_valid
    expect(ebook.errors[:file]).to include("must be a PDF or EPUB")
  end

  it "rejects a file larger than the max size" do
    ebook = build(:ebook)
    oversized = "a" * (Ebook::MAX_FILE_SIZE + 1)
    ebook.file.attach(
      io: StringIO.new(oversized),
      filename: "big.pdf",
      content_type: "application/pdf"
    )
    expect(ebook).not_to be_valid
    expect(ebook.errors[:file].join).to match(/too large/)
  end

  describe ".search" do
    it "matches by title, author, or file_name" do
      a = create(:ebook, title: "Ruby Basics", author: "Jane")
      b = create(:ebook, title: "Flutter Guide", author: "Ruby Smith")
      c = create(:ebook, title: "Other Book", author: "Someone")

      results = Ebook.search("Ruby")
      expect(results).to include(a, b)
      expect(results).not_to include(c)
    end

    it "returns all ebooks when query is blank" do
      create_list(:ebook, 2)
      expect(Ebook.search(nil).count).to eq(2)
      expect(Ebook.search("").count).to eq(2)
    end
  end

  describe "#as_json_summary" do
    it "includes a download_url when file is attached" do
      ebook = create(:ebook)
      json = ebook.as_json_summary
      expect(json[:download_url]).to eq("/api/ebooks/#{ebook.id}/download")
    end

    it "sets cover_url to nil when no cover attached" do
      ebook = create(:ebook)
      expect(ebook.as_json_summary[:cover_url]).to be_nil
    end
  end
end