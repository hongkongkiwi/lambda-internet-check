'use strict';

const isOnline = require('is-online');

exports.handler = (event, context, callback) => {
  console.log('Checking...');
  isOnline({timeout: parseInt(process.env.TIMEOUT)}).then(online => {
    console.log('Online Status:',online ? 'Online' : 'Offline');
    if (online) {
      return callback(null, 'We are online');
    }
    callback('OH NO! We are offline!');
  });
}
