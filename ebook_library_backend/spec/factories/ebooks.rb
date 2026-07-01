FactoryBot.define do
  factory :ebook do
    title { "Sample Book" }
    author { "Sample Author" }

    after(:build) do |ebook|
      ebook.file.attach(
        io: StringIO.new("%PDF-1.4 fake pdf content"),
        filename: "sample.pdf",
        content_type: "application/pdf"
      )
    end
  end
end