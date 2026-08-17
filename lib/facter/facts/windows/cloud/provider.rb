# frozen_string_literal: true

module Facts
  module Windows
    module Cloud
      class Provider
        FACT_NAME = 'cloud.provider'

        def call_the_resolver
          virtual = Facter::Resolvers::Windows::Virtualization.resolve(:virtual)
          provider = case virtual
                     when 'hyperv'
                       'azure' if Facter::Resolvers::Az.resolve(:metadata_available)
                     when 'kvm', 'xen'
                       'aws' if Facter::Resolvers::Ec2.resolve(:metadata_available)
                     when 'gce'
                       'gce' if Facter::Resolvers::Gce.resolve(:metadata_available)
                     end

          Facter::ResolvedFact.new(FACT_NAME, provider)
        end
      end
    end
  end
end
