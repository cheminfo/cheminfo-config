'use strict';

const processNmr = require('../../processNmr');
const path = require('path');

module.exports = {
    getID: function (filename, contents) {
        return path.parse(filename).name;
    },
    getOwner: function (filename, contents) {
        return 'nmr@cheminfo.org';
    },
    parse: function (filename, contents) {
        return {
            jpath: 'nmr',
            data: processNmr(contents.toString()),
            type: 'jcamp',
            content_type: 'chemical/x-jcamp-dx'
        };
    }
};
