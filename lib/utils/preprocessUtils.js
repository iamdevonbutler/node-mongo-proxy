const {isType, getType, isObjectId} = require('./mainUtils');
const {deepSet} = require('lodash-deep');
const {uniq, flatten} = require('lodash');

const self = module.exports;

/**
 * Parses args to identify operation as an upsert.
 * @param {Array} args
 * @return {Boolean}
 * @tests none.
 */
self.isUpsert = (args) => {
  return args && args[2] ? args[2].upsert : false;
}

/**
 * Remove update semantics from a payload path.
 * @param {String} key
 * @return {String}
 * @tests none.
 */
self.cleanUpdateKey = (key) => {
  return key.replace('$.', '').replace(/\.\d+/g, '').replace(/\$\w+\.?/g, '');
}

/**
 * Get subdocument schema from full collection schema.
 * @param {String} key
 * @param {Object} schema
 * @param {Number} [depth].
 * @return {Object}
 * @tests unit.
 * @api public.
 */
self.getSubdocumentSchema = (key, schema, depth) => {
  var keys, len, schema2 = {};
  len = key.split('.').length;
  keys = Object.keys(schema);
  keys
    .filter(key2 => key2.startsWith(key) && key2.length > key.length)
    .filter(key2 => depth ? key2.split('.').length <= len + depth : true)
    .forEach(key2 => schema2[key2] = schema[key2]);
  return schema2;
};

/**
 * Given a payload, return an array of all field keys.
 * @param {Object} payload.
 * @return {Array}
 */
self.getPayloadKeys = (payload) => {
  var keys;
  keys = [];
  Object.keys(payload).forEach((key) => {
    var value, type;
    value = payload[key];
    type = getType(value);
    if (type === 'object') {
      let nestedKeys;
      nestedKeys = self.getPayloadKeys(value).map(item => key+'.'+item);
      keys = keys.concat(nestedKeys);
    }
    else if (type === 'array') {
      keys.push(key);
      value.forEach((value2) => {
        var type;
        type = getType(value2);
        if (type === 'object') {
          let nestedKeys;
          nestedKeys = self.getPayloadKeys(value2).map(item => key+'.'+item);
          keys = keys.concat(nestedKeys);
        }
      });
    }
    else {
      keys.push(key);
    }
  });
  return keys.map(self.cleanUpdateKey);
};

/**
 * Given an query, return an array of fields that are being queried.
 * @param {Object} query
 * @param {String} [parentKey] if processing a nested object with an $elemMatch,
 * provide the parents path to prepend to the child field.
 * @return {Array}
 * @api public.
 * @tests unit. @todo migrate tests/
 */
self.getQueryFields = (query, parentKey) => {
  var fields = [];

  // Itterate over each field in query.
  for (let fieldKey in query) {
    let fullKey, valueType, fieldValue, isObjectID, isMongoOperator;
    fieldValue = query[fieldKey];
    // Mongo operators begin w/ `$`.
    isMongoOperator = fieldKey.indexOf('$') === 0;
    // Strip mongodb operators `.$` and `.0` from fieldKey;
    fieldKey = fieldKey.replace('$.', '').replace(/\.\d/g, '');
    // Prepend parentKey to current fieldKey if it exists.
    fullKey = parentKey ? parentKey + '.' + fieldKey : fieldKey;
    // ObjectID will be of type object, but we want it to be a string.
    valueType =  getType(fieldValue);
    valueType = valueType === 'object' && isObjectId(fieldValue) ? 'string' : valueType;
    // If the query is using a logical $and operator or such, its value
    // will be an array.
    if (valueType === 'array' && isMongoOperator) {
      fieldValue.forEach((item) => {
        if (isType(item, 'object')) {
          fields.push(self.getQueryFields(item));
        }
      });
      continue;
    }
    // If the field value is an object, it will contain other fields, or
    // mongodb operators containing fields.
    if (valueType === 'object') {
      // $elemMatch is unique in that its children are objects in an array.
      // As such, it's children will have a key equal to the parent
      // of $elemMatch (not $elemMatch itself).
      if (fieldKey === '$elemMatch') {
        fields.push(self.getQueryFields(fieldValue, parentKey));
      }
      else {
        // fieldKey is parent key for next call.
        let result = self.getQueryFields(fieldValue, fullKey);
        if (result.length) {
          fields.push(result);
          continue;
        }
      }
    }

    if (!isMongoOperator) {
      // Prepend parent key to fieldKey if it exists.
      fields.push(fullKey);
    }

  }
  fields = flatten(fields);
  // Filter out query operators.
  fields = fields.filter((field) => {
    return field.indexOf('$') !== 0;
  });
  return uniq(fields);
};

/**
 * Given a partial payload, e.g...
 *  'account.notifications': { $each: [1,2,3], $slice: -5 }
 * remove array modifiers from Object and return them.
 * @param {Object} payload.
 * @return {Array|null}
 * @api private.
 * @tests none.
 */
self.spliceModifiers = (payload) => {
  var keys, modifiers = [];
  keys = Object.keys(payload);
  keys.forEach((key) => {
    let obj = {};
    if (key === '$each') {
      return;
    }
    if (key.indexOf('$') === 0) {
      obj[key] = payload[key];
      modifiers.push(obj);
      delete payload[key];
    }
  });
  return modifiers.length ? modifiers : null;
};