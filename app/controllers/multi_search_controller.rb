require 'concurrent'

class MultiSearchController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :search_form_embed
  after_action :no_x_frame_options, only: "search_form_embed"

  class_attribute :main_engine_ids
  self.main_engine_ids = %w{catalog articles}
  helper_method :main_engine_ids

  class_attribute :secondary_engine_ids
  self.secondary_engine_ids = %w{databases reserves website flash}
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

  def search_form_embed
    render layout: 'embed'
  end


  protected

  def query
    @query ||= params[:q].try(:strip).presence
  end
  helper_method :query

  def immediate_search_results
    @immediate_search_results ||= begin
      immediate_engine_ids = engine_ids.find_all { |id| BentoSearch.get_engine(id).display_configuration.ajax != :auto   }

      BentoSearch::ConcurrentSearcher.new(*immediate_engine_ids).search(query).results
    end
  end

  def background_search_engines
    @background_search_engines ||= begin
      bg_engines = engine_ids.collect do |id|
        engine = BentoSearch.get_engine(id)
        engine if engine.display_configuration.ajax == :auto
      end.compact

      bg_engines.collect do |engine|
        [engine.engine_id, engine]
      end.to_h
    end
  end


  # Returns a hash key'd by ID. The value will be a hash which always has an engine key/value,
  # and also has a results key/value if target is NOT going to be searched bg-ajax.
  def search_results
    @search_results ||= begin
      if query
        background_search_engines.merge(immediate_search_results)
      else
        {}
      end
    end
  end
  helper_method :search_results

  def bento_search_args_for_object(obj)
    if obj == BentoSearch::Results
      [obj]
    else # it's a BentoSearch::SearchEngine loaded in bg ajax
      [obj, {query: query, load: :ajax_auto}]
    end
  end
  helper_method :bento_search_args_for_object

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

  def no_x_frame_options
    response.headers.delete("X-Frame-Options")
  end

end
