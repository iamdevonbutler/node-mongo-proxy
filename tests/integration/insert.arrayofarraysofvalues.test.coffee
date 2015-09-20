'use strict'

require('../helpers/setup')

#Module dependencies.
should = require('chai').should()
expect = require('chai').expect
assert = require('chai').assert

db = require('../../lib')
schema = require('../fixtures/schema.arrayofarraysofvalues')

describe 'insert(): array of arrays of values:', ->

  beforeEach (done) ->
    models = { users: { schema: schema } }
    db.addModels(models)
    done()

  it 'should throw an error given a undefined value', (done) ->
    doc = { account: {} }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('required')
      done()

  it 'should filter null values, transform, sanitize, trim and lowercase values', (done) ->
    doc = { locations: [ null, [' JAY ', '<script>jay</script>', null ] ] }
    db.users.insert(doc).then (result) ->
      db.users.findOne({}).then (result) ->
        result.locations[0][0].should.eql('jay!')
        result.locations[0][1].should.not.eql('<script>jay</script>')
        result.locations.length.should.eql(1)
        result.locations[0].length.should.eql(2)
        done()

  it 'should throw an error given an invalid type', (done) ->
    doc = { locations: [ [1] ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('type')

    doc = { locations: [ 'a' ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('type')

    doc = { locations: {a:1} }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('type')
      done()

  it 'should throw an error given a conflict w/ the custom validate function', (done) ->
    doc = { locations: [ ['reject'] ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('validate')
      done()

  it 'should throw an error given a document in violation of the minLength constraint', (done) ->
    doc = { locations: [] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('minLength')

    doc = { locations: [ [] ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('minLength')

    doc = { locations: [ ['bos', ''] ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('minLength')
      done()


  it 'should throw an error given a document in violation of the maxLength constraint', (done) ->
    doc = { locations: [ ['bos', 'nyc', 'dc'] ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('maxLength')

    doc = { locations: [ ['bos', 'abcdefghijklmnopqrstuvwxyz'] ] }
    try
      db.users.insert(doc).then (result) ->
        done(result)
    catch e
      e.errors.length.should.eql(1)
      e.errors[0].property.should.eql('maxLength')
      done()
