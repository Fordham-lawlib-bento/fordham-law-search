require 'concurrent'

class MultiSearchController < ApplicationController
  class_attribute :main_engine_ids
  self.main_engine_ids = %w{catalog articles}
  helper_method :main_engine_ids

  class_attribute :secondary_engine_ids
  self.secondary_engine_ids = %w{website databases reserves flash}
  helper_method :secondary_engine_ids

  def self.engine_ids
    main_engine_ids + secondary_engine_ids
  end
  def engine_ids
    main_engine_ids + secondary_engine_ids
  end



  include LinkOutHelper
  helper LinkOutHelper


  def index
    if redirect = redirect_to_search
      redirect_to redirect, status: :found
      return
    end

    # trigger lazy load in controller, just cause
    search_results
  end


  protected

  def query
    @query ||= params[:q].try(:strip).presence
  end
  helper_method :query

  def search_results
    @search_results ||= begin
      if query
        # Execute all the searches in futures, so they each get their own thread,
        # then assemble them all into a hash of engine_id => Response.
        # Making them into a hash will wait on each one for value, so will wait
        # for them all to complete.
        BentoSearch::ConcurrentSearcher.new(*engine_ids).search(query).results
      else
        {}
      end
    end
  end
  helper_method :search_results

  def engines
    engine_ids.collect do |engine_id|
      engine = BentoSearch.get_engine(engine_id)
    end
  end

  def search_type_select_options
    [['ALL', nil]].concat(
      engines.collect do |e|
        if e.configuration.for_display.link_out
          [ e.configuration.for_display.heading || e.configuration.id, e.configuration.id ]
        end
      end.compact
    )
  end
  helper_method :search_type_select_options

  def redirect_to_search
    if params[:direct_search].present? && params[:q].present? && engine = BentoSearch.get_engine(params[:direct_search])
      complete_link_out_template( engine.configuration.for_display.link_out, params[:q]  )
    end
  end

end
