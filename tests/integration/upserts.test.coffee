'use strict'

require('../helpers/setup')

#Module dependencies.
should = require('chai').should()
expect = require('chai').expect
assert = require('chai').assert

db = require('../../lib')
schema = require('../fixtures/schema.values')

describe 'Upserts:', ->

  beforeEach (done) ->
    db.addModel('users', { schema: schema })
    doc = { account: { friends: ['gab'], name: 'jay' } }
    db.users.insert(doc).then (result) ->
      done()

  describe '$set', ->
    # This prevents adding fields to the document from the query.
    it 'should throw an error when the query contains fields that are not in schema', (done) ->
      query = { 'account.name': 'jay', 'account.email': 'bob@bob.com' }
      payload = { $set: { 'account.name': 'gab' } }
      try
        db.users.update(query, payload, { upsert: true }).then (result) ->
          done(result)
      catch e
        e.errors.should.be.ok
        done()

    # it 'should update a document given a matching query', (done) ->
    #   query = { 'account.name': 'hey jay' }
    #   payload = { $set: { 'account.name': 'gab' } }
    #   db.users.update(query, payload, { upsert: true }).then (result) ->
    #     db.users.find().then (result) ->
    #       result.toArray().then (result) ->
    #         result.length.should.eql(1)
    #         result[0].account.name.should.eql('hey gab')
    #         result[0].account.friends.should.eql([])
    #         result[0].newsletter.should.eql(true)
    #         #  Using different query syntax.
    #         query = { account: { name: 'hey gab', friends: [] } }
    #         payload = { account: { name: 'lou' } }
    #         db.users.update(query, payload, { upsert: true }).then (result) ->
    #           db.users.find().then (result) ->
    #             result.toArray().then (result) ->
    #               result.length.should.eql(1)
    #               result[0].account.name.should.eql('hey lou')
    #               result[0].newsletter.should.eql(true)
    #               done()

    it 'should insert a document given a non matching query', ->

  describe '$setOnInsert', ->
  describe 'findAndModify()', ->