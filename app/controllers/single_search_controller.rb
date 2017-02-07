class SingleSearchController < ApplicationController
  helper LinkOutHelper

  def index
    results
  end

  protected

  def engine_id
    params[:engine]
  end
  helper_method :engine_id

  def query
    @query ||= params[:q].try(:strip).presence
  end
  helper_method :query

  def engine
    @engine ||= BentoSearch.get_engine(engine_id)
  end
  helper_method :engine

  def results
    unless defined?(@results)
      @results = engine.search(query: query, per_page: 10, page: params[:page]) if query
    end
    @results
  end
  helper_method :results

end
