# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe MoreLikeThisRecord do
    describe '#initialize' do
      context 'with non integer record_id' do
        it 'raises Supplejack::MalformedRequest error' do
          expect { described_class.new('notvalidid') }.to raise_error(Supplejack::MalformedRequest)
        end
      end

      context 'with valid id and no options' do
        let(:more_like_this) { described_class.new(101) }

        it 'has default params' do
          expect(more_like_this.params).to eq({ frequency: 1 })
        end

        it 'has id' do
          expect(more_like_this.id).to eq 101
        end
      end

      context 'with valid id and options' do
        let(:more_like_this) { described_class.new(1, { frequency: 2, mlt_fields: %i[title description] }) }

        it 'has default params' do
          expect(more_like_this.params).to eq({ frequency: 2, mlt_fields: 'title,description' })
        end
      end
    end

    describe '#records' do
      let(:more_like_this) { described_class.new(101, { frequency: 2, mlt_fields: %i[title description] }) }

      it 'requests more_like_this api with params' do
        allow(more_like_this).to receive(:get).with('/records/101/more_like_this', { frequency: 2, mlt_fields: 'title,description' }).and_return('record' => {})

        more_like_this.records
      end

      context 'when record not found' do
        before { allow(more_like_this).to receive(:get).and_raise(RestClient::ResourceNotFound) }

        it 'raises an error' do
          expect { more_like_this.records }.to raise_error(Supplejack::RecordNotFound)
        end
      end

      context 'when there is standard error on API call' do
        before { allow(more_like_this).to receive(:get).and_raise(StandardError) }

        it 'returns an empty array' do
          expect(more_like_this.records).to eq []
        end
      end
    end
  end
end
