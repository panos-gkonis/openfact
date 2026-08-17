# frozen_string_literal: true

module Facts
  module Linux
    module Cloud
      class Provider
        FACT_NAME = 'cloud.provider'

        def call_the_resolver
          provider = case Facter::Util::Facts::Posix::VirtualDetector.platform
                     when 'hyperv'
                       'azure' if Facter::Resolvers::Az.resolve(:metadata_available)
                     when 'kvm', 'xen', 'xenhvm'
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
