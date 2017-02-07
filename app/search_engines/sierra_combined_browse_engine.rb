# A weird search engine that merges results from multiple SierraBrowseEngines,
# sorting alphabetically and limiting to max_results.
#
# Weirder, it sometimes does multiple searches on each component engine for
# a given multi-word query, tokenizing the query and doing each, to try to
# deal with Sierra browse search not really being what we want.
#
# We don't use BentoSearch::ConcurrentSearcher, because it doesn't support
# the variation in queries we want. But code is based on that, re-mixed.
#
# Configuration parameters:
#
#  component_engine_ids: (required) Array of id's of BentoSearch engines configured and
#     registered, that will be used as components.
#  tokenize_multi_search: do the weird tokenize thing, default true, but turn to false
#      to disable.
class SierraCombinedBrowseEngine
  include BentoSearch::SearchEngine

  def self.default_configuration
    {
      tokenize_multi_search: true
    }
  end

  def search_implementation(args)
    search_data = multi_engine_search(args[:query])

    master_results = BentoSearch::Results.new

    ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
      search_data.each_pair do |(engine_id, query), future|
        results = future.value
        master_results.concat results
        if results.failed?
          master_results.error = results.error
        end
      end
    end

    master_results.total_items = nil
    master_results.sort_by! {|i| i.title.downcase }

    return master_results
  end

  def self.required_configuration
    %w{component_engine_ids}
  end

  protected

  # Returns a weird hash structure, where keys are a duple, and values
  # are a future with search results.
  #
  #    { [engine_id, query] => future }
  def multi_engine_search(query)
    queries = tokenize_query(query)
    engines = {}

    configuration.component_engine_ids.each do |id|
      queries.each do |q|
        engine = BentoSearch.get_engine(id).tap { |e| e.auto_rescued_exceptions = e.auto_rescued_exceptions + [StandardError] }

        key = [id, q]
        engines[key] = future_search(engine, q)
      end
    end
    return engines
  end

  # Split onto spaces into first word, and rest of words. If only one word,
  # will get an array back with one element.
  def tokenize_query(query)
    if configuration.tokenize_multi_search
      query.split(/\s+/, 2)
    else
      [query]
    end
  end

  # Returns the engine results, wrapped in a rails executor, wrapped in a
  # future.
  def future_search(engine, query)
    Concurrent::Future.execute do
      Rails.application.executor.wrap do
        engine.search(query)
      end
    end
  end



end
