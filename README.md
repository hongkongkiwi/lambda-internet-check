# Lambda Internet Checker

 I created this to help setting up the confusing mess that is Amazon VPCs to make sure my Lambda function could access the internet.

 ### Install

 `git clone https://github.com/hongkongkiwi/lambda-internet-check.git`

 If you want an easy way to update the code to lambda, simply make sure that the aws-cli tools are installed and run my publish script.
 `npm run upload`

 Otherwise you can just zip up index.js & node_modules into a zip
 `zip -r code.zip node_modules index.js` and upload using the Amazon Lambda web interface.

 ### Run

 If you want to test locally you can run:
`node tests/test`

Or upload and run in the normal way for Lambda functions.
