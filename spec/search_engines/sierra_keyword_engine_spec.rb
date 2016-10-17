require 'rails_helper'

describe SierraKeywordEngine do
  it "gets basic search results" do
    results = SierraKeywordEngine.new.search("brooklyn")

    expect(results.total_items).to be_present
    expect(results.total_items > 0).to be true

    expect(results.count > 0).to be true
    results.each do |item|
      expect(item.title).to be_present, item.to_json

      # not all results have authors, gah
      if item.authors.present?
        expect(item.authors.all? { |a| a.display.present? }).to be(true), item.to_json
      end

      # not everything has a year
      #expect(item.year).to be_present, item.to_json

      expect(item.format_str).to be_present, item.to_json

      # has call number and location OR extra link
      expect(item.custom_data[:call_number] || item.other_links).to be_present, item.to_json

      expect(item.custom_data[:location]).to be_present, item.to_json
    end
  end
end
