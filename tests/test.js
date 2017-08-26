//const testData = require('./testData.json');
const testData = null;
const index = require('../index');

index.handler(testData, this, (err, result) => {
  if (err) return console.error(err);
  console.log(result);
});
