require 'concurrent'

class MultiSearchController < ApplicationController
  class_attribute :engines
  self.engines = %w{catalog articles reserves databases website flash}

  helper LinkOutHelper


  def index
    # We're getting weird deadlock I think coming from auto-load concurrency errors, unless we force
    # auto-loading of everything first with a test run. Bah. TODO, shouldn't
    # need this.
    e = BentoSearch.global_registrar.get_engine("catalog")
    e.search("foo")

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
        engines.collect do |engine_id|
          # have to collect engines not in the future for reasons I don't fully
          # understand, or there seems to be a deadlock.
          engine = BentoSearch.get_engine(engine_id)
          Concurrent::Future.execute { engine.search(query) }
        end.collect { |future| [future.value!.engine_id, future.value!] }.to_h
      else
        {}
      end
    end
  end
  helper_method :search_results

end
