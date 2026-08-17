# frozen_string_literal: true

module Facter
  module Resolvers
    class Az < BaseResolver
      init_resolver

      AZ_METADATA_URL = 'http://169.254.169.254/metadata/instance?api-version=2020-09-01'
      AZ_SESSION_TIMEOUT = 5

      class << self
        private

        def post_resolve(fact_name, _options)
          log.debug('Querying Az metadata')
          @fact_list.fetch(fact_name) { read_fact(fact_name) }
        end

        def read_fact(fact_name)
          read_metadata if %i[metadata metadata_available].include?(fact_name)
        end

        def read_metadata
          @fact_list[:metadata] = {}
          data = get_data_from(AZ_METADATA_URL)
          @fact_list[:metadata] = JSON.parse(data) unless data.empty?
          @fact_list[:metadata_available] = !@fact_list[:metadata].empty?
        end

        def get_data_from(url)
          headers = { Metadata: 'true' }
          Facter::Util::Resolvers::Http.get_request(url, headers, { session: determine_session_timeout }, false)
        end

        def determine_session_timeout
          session_env = ENV.fetch('AZ_SESSION_TIMEOUT', nil)
          session_env ? session_env.to_i : AZ_SESSION_TIMEOUT
        end
      end
    end
  end
end
