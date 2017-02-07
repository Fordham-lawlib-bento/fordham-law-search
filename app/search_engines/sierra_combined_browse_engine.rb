#require 'bento_search/concurrent_searcher'

# A weird search engine that merges results from multiple SierraBrowseEngines,
# sorting alphabetically and limiting to max_results.
class SierraCombinedBrowseEngine
  include BentoSearch::SearchEngine

  def search_implementation(args)
    searcher = BentoSearch::ConcurrentSearcher.new(*configuration.component_engine_ids)

    searcher.search(args[:query])

    master_results = BentoSearch::Results.new

    searcher.results.each_pair do |id, results|
      master_results.concat results
      if results.failed?
        master_results.error = results.error
      end
    end

    master_results.total_items = nil
    master_results.sort_by! {|i| i.title.downcase }

    return master_results
  end
end
