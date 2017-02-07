require 'rails_helper'

describe SierraBrowseEngine do
  let(:search_type) { "p" }
  let(:format_str) { "Some Thing" }
  let(:engine) { SierraBrowseEngine.new(id: "mock", search_type: search_type, format_str: format_str) }

  describe "no results" do
    let(:query) { "adzzzzzzzzakdjfzzzzz" }

    it "returns no results" do
      results = engine.search(query)
      expect(results.failed?).not_to be(true)
      expect(results.size).to eq(0)
    end
  end

  describe "multiple results" do
    let(:query) { "s" }

    it "returns results" do
      results = engine.search(query)
      expect(results.failed?).not_to be(true)
      expect(results.size > 0).to be(true)
      results.each do |result|
        expect(result.title).to be_present
        expect(result.title.downcase.start_with?(query)).to be(true)

        expect(result.format_str).to eq(format_str)

        expect(result.link).to be_present
        expect(Addressable::URI.parse(result.link)).to be_absolute
      end
    end

    describe "with limit" do
      let(:max_results) { 1 }
      let(:engine) { SierraBrowseEngine.new(max_results: max_results, id: "mock", search_type: search_type, format_str: format_str) }
      it "returns results within max" do
        results = engine.search(query)
        expect(results.failed?).not_to be(true)
        expect(results.size).to eq(max_results)
      end
    end
  end

  describe "super entry result" do
    # If you match one heading that has multiple "next level" headings, you
    # get a weird super-heading result that has to be handled special.
    # Currently course name "civil" is such a result.
    let(:query) { "civil" }
    let(:search_type) { "r" }

    it "returns proper heading result" do
      results = engine.search(query)

      expect(results.size).to eq(1)

      result = results.first

      expect(result.title).to be_present
      expect(result.title.downcase.start_with?(query)).to be(true)

      expect(result.format_str).to eq(format_str)

      expect(result.link).to be_present
      expect(Addressable::URI.parse(result.link)).to be_absolute
    end
  end

  describe "one result" do
    # Sierra jumps straight to bib record when there's only one hit
    let(:query) { "silverstein" }

    it "Returns one result" do
      results = engine.search(query)
      expect(results.failed?).not_to be(true)
      expect(results.size).to eq(1)

      result = results.first

      expect(result.title).to be_present
      expect(result.title.downcase.start_with?(query)).to be(true)

      expect(result.format_str).to eq(format_str)

      expect(result.link).to be_present
      expect(Addressable::URI.parse(result.link)).to be_absolute
    end
  end

end
