require 'spec_helper'

class Band   ; include Mongoid::Document end
class Person ; include Mongoid::Document end
class Rating ; include Mongoid::Document end
class Game
  include Mongoid::Document
  field :name, type: String
  has_many :ratings
end


def expect_query(number, &block)
  at_first = Moped.logger.count
  block.call
  but_then = Moped.logger.count
  expect(but_then - at_first).to(eq(number), "Expected to receive #{number} queries, it received #{but_then - at_first}")
end

def expect_no_queries(&block)
  expect_query(0, &block)
end

describe Mongoid::QueryCache do

  around do |spec|
    Mongoid::QueryCache.clear_cache
    Mongoid::QueryCache.cache { spec.run }
  end

  context 'when querying for a single document' do

    [ :first, :one, :last ].each do |method|

      before do
        Band.all.send(method)
      end

      context 'when query cache disable' do

        before do
          Mongoid::QueryCache.enabled = false
        end

        it 'queries again' do
          expect_query(1) do
            Band.all.send(method)
          end
        end
      end

      context 'with same selector' do

        it 'does not query again' do
          expect_no_queries do
            Band.all.send(method)
          end
        end
      end

      context 'with different selector' do

        it 'queries again' do
          expect_query(1) do
            Band.where(id: 1).send(method)
          end
        end
      end
    end
  end

  context 'when querying in the same collection' do

    before do
      binding.pry
      Band.all.entries
    end

    context 'when query cache disable' do

      before do
        Mongoid::QueryCache.enabled = false
      end

      it 'queries again' do
        expect_query(1) do
          Band.all.entries
        end
      end
    end

    context 'with same selector' do

      it 'does not query again' do
        expect_no_queries do
          Band.all.entries
        end
      end

      context 'when querying only the first' do
        let(:game) { Game.create!(name: '2048') }

        before do
          game.ratings.where(:value.gt => 5).asc(:id).all.entries
        end

        it 'queries again' do
          expect_query(1) do
            game.ratings.where(:value.gt => 5).asc(:id).first
          end
        end
      end

      context 'limiting the result' do
        it 'queries again' do
          expect_query(1) do
            Band.limit(2).all.entries
          end
        end
      end

      context 'specifying a different skip value' do
        before do
          Band.limit(2).skip(1).all.entries
        end

        it 'queries again' do
          expect_query(1) do
            Band.limit(2).skip(3).all.entries
          end
        end
      end
    end

    context 'with different selector' do

      it 'queries again' do
        expect_query(1) do
          Band.where(id: 1).entries
        end
      end
    end
  end

  context 'when querying in different collection' do

    before do
      Person.all.entries
    end

    it 'queries again' do
      expect_query(1) do
        Band.all.entries
      end
    end
  end

  context 'when inserting a new document' do

    before do
      Band.all.entries
      Band.create!
    end

    it 'queries again' do
      expect_query(1) do
        Band.all.entries
      end
    end
  end

  context 'when deleting all documents' do

    before do
      Band.create!
      Band.all.entries
      Band.delete_all
    end

    it 'queries again' do
      expect_query(1) do
        Band.all.entries
      end
    end
  end

  context 'when destroying all documents' do

    before do
      Band.create!
      Band.all.entries
      Band.destroy_all
    end

    it 'queries again' do
      expect_query(1) do
        Band.all.entries
      end
    end
  end

  context 'when inserting an index' do

    it 'does not cache the query' do
      Mongoid::QueryCache.should_receive(:cache_table).never
      Band.collection.indexes.create(name: 1)
    end
  end
end

describe Mongoid::QueryCache::Middleware do

  let :middleware do
    Mongoid::QueryCache::Middleware.new(app)
  end

  context 'when not touching mongoid on the app' do

    let(:app) do
      ->(env) { @enabled = Mongoid::QueryCache.enabled?; [200, env, 'app'] }
    end

    it 'returns success' do
      code, _ = middleware.call({})
      expect(code).to eq(200)
    end

    it 'enables the query cache' do
      middleware.call({})
      expect(@enabled).to be true
    end
  end

  context 'when querying on the app' do

    let(:app) do
      ->(env) {
        Band.all.entries
        [200, env, 'app']
      }
    end

    it 'returns success' do
      code, _ = middleware.call({})
      expect(code).to eq(200)
    end

    it 'cleans the query cache after reponds' do
      middleware.call({})
      expect(Mongoid::QueryCache.cache_table).to be_empty
    end
  end
end