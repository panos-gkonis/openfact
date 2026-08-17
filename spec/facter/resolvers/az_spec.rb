# frozen_string_literal: true

describe Facter::Resolvers::Az do
  subject(:az) { Facter::Resolvers::Az }

  let(:uri) { 'http://169.254.169.254/metadata/instance?api-version=2020-09-01' }
  let(:headers) { { Metadata: 'true' } }
  let(:timeouts) { { session: 5 } }

  before do
    allow(Facter::Util::Resolvers::Http).to receive(:get_request)
      .with(uri, headers, timeouts, false).and_return(output)
  end

  after do
    az.invalidate_cache
  end

  context 'when no exception is thrown' do
    let(:output) { '{"azEnvironment":"AzurePublicCloud"}' }

    it 'returns az metadata' do
      expect(az.resolve(:metadata)).to eq({ 'azEnvironment' => 'AzurePublicCloud' })
    end

    it 'sets metadata availability without another request' do
      az.resolve(:metadata)

      expect(az.resolve(:metadata_available)).to be(true)
      expect(Facter::Util::Resolvers::Http).to have_received(:get_request)
        .with(uri, headers, timeouts, false).once
    end
  end

  context "when a proxy is set with ENV['http_proxy']" do
    before do
      stub_const('ENV', { 'http_proxy' => 'http://example.com' })
    end

    let(:output) { '{"azEnvironment":"AzurePublicCloud"}' }

    it 'returns az metadata' do
      expect(az.resolve(:metadata)).to eq({ 'azEnvironment' => 'AzurePublicCloud' })
    end
  end

  context 'when an exception is thrown' do
    let(:output) { '' }

    it 'returns empty az metadata' do
      expect(az.resolve(:metadata)).to eq({})
    end
  end

  describe 'metadata availability' do
    before do
      allow(Facter::Util::Resolvers::Http).to receive(:get_request)
        .with(uri, headers, timeouts, false).and_return(availability_output)
    end

    context 'when the metadata service responds' do
      let(:availability_output) { output }
      let(:output) { '{"azEnvironment":"AzurePublicCloud"}' }

      it 'returns true and caches the result' do
        2.times { az.resolve(:metadata_available) }

        expect(az.resolve(:metadata_available)).to be(true)
        expect(Facter::Util::Resolvers::Http).to have_received(:get_request)
          .with(uri, headers, timeouts, false).once
      end

      it 'still fully resolves metadata after the availability check' do
        az.resolve(:metadata_available)

        expect(az.resolve(:metadata)).to eq({ 'azEnvironment' => 'AzurePublicCloud' })
        expect(Facter::Util::Resolvers::Http).to have_received(:get_request)
          .with(uri, headers, timeouts, false).once
      end
    end

    context 'when the metadata service does not respond' do
      let(:availability_output) { '' }
      let(:output) { '' }

      it 'returns false' do
        expect(az.resolve(:metadata_available)).to be(false)
      end
    end
  end
end
