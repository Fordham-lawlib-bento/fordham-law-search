require 'rails_helper'

describe SierraKeywordEngine do
  it "gets basic search results" do
    results = SierraKeywordEngine.new(id: 'mock').search("brooklyn")

    expect(results.engine_id).to eq("mock")

    expect(results.total_items).to be_present
    expect(results.total_items > 0).to be true

    expect(results.count > 0).to be true
    results.each do |item|
      expect(item.engine_id).to eq("mock")

      expect(item.title).to be_present, item.to_json
      expect(item.link).to be_present, item.to_json

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

  describe "limited max_results" do
    let(:max_results) { 6 }
    it "returns only max_results" do
      results = SierraKeywordEngine.new(max_results: 6, id: 'mock').search("brooklyn")
      expect(results.count).to eq(6)
    end
  end

  describe "non-ascii search and results" do
    it "are good chars" do
      results = SierraKeywordEngine.new.search("Cirión")

      expect(results.count > 0).to be true
      results.each do |item|
        expect(item.title.valid_encoding?).to be(true), item.to_json
        expect(item.title.index('�')).to be_nil

        expect(item.authors.all? { |a| a.display.valid_encoding? }).to be(true), item.to_json
        expect(item.authors.all? { |a| a.display.index('�').nil? }).to be(true)
      end
    end
  end

  describe "error conditions" do
    it "404 response" do
      results = SierraKeywordEngine.new(id: 'test', base_url: "http://lawpac.lawnet.fordham.edu/bad/path/nope").search("foo")
      expect(results.failed?).to be true
      expect(results.engine_id).to eq('test')
    end

    it "bad host" do
      results = SierraKeywordEngine.new(id: 'test', base_url: "http://no-such-host.lawnet.fordham.edu").search("foo")
      expect(results.failed?).to be true
      expect(results.engine_id).to eq('test')
    end

    it "no results" do
      # Sierra doesn't like empty search
      results = SierraKeywordEngine.new(id: 'test').search("adlfjakldfjopieajirojdfaadf")
      expect(results.failed?).to be false
      expect(results.count).to eq(0)
      expect(results.engine_id).to eq('test')
    end
  end

  describe "construct_search_url" do
    describe "extra_webpac_query_params" do
      let(:extra_params) { {m: 'f', foo: 'bar'} }
      let(:engine) { SierraKeywordEngine.new(extra_webpac_query_params: extra_params ) }
      it 'includes the extra params' do
        url = engine.construct_search_url(query: 'some search')
        query_params = CGI.parse(URI.parse(url).query)

        extra_params.each_pair do |k, v|
          expect(query_params[k.to_s]).to eq([v])
        end
      end
    end
  end

end
