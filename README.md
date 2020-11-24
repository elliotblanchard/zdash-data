Setup references this article: https://www.techcareerbooster.com/blog/use-activerecord-in-your-ruby-project
Article on storing arrays (column should be type text): http://amberonrails.com/storing-arrays-in-a-database-field-w-rails-activerecord/

API reference page: https://zcha.in/api

Sample API call: https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit=10&offset=0

Sample Transaction: [{"hash":"001faafa01be4dcfcd0457d3d0a5124ba89e40ae8492b579db294400e6618d37","mainChain":false,"fee":0.0000245,"type":"valueTransfer","shielded":false,"index":-1,"blockHash":"","blockHeight":-1,"version":4,"lockTime":0,"timestamp":1606158507,"time":1606158507,"vin":[{"coinbase":"","retrievedVout":{"n":1,"scriptPubKey":{"addresses":["t1dQJw7sRymAezMiDc4L9Xn5NyB314Vppmn"],"asm":"","hex":"","reqSigs":0,"type":""},"value":0.10041761,"valueZat":0},"scriptSig":{"asm":"3044022017da7131233559b73a3ea101a1baee6cfae8f4c8d43e8f86c7d50b4c62f7eacb02207c2b3470a98e852ce7908af3b14633f6f0b03c85e51eab914a69cd2c71e20ca2[ALL] 022e4a1fa73107646c38ae26696c9c1136211259a36a7519fc76aba42dd826899c","hex":"473044022017da7131233559b73a3ea101a1baee6cfae8f4c8d43e8f86c7d50b4c62f7eacb02207c2b3470a98e852ce7908af3b14633f6f0b03c85e51eab914a69cd2c71e20ca20121022e4a1fa73107646c38ae26696c9c1136211259a36a7519fc76aba42dd826899c"},"sequence":4294967295,"txid":"ace7b5e8932b6bf64d08fda00a6b87a0f8d845de030b97603e30b947f459d225","vout":1}],"vout":[{"n":0,"scriptPubKey":{"addresses":["t1QAw38fUYJ4zHTaHsCbpySLAR4YC91BSc4"],"asm":"OP_DUP OP_HASH160 4517b65ac830ada301eefdc69ee8e77e7dc5c7a8 OP_EQUALVERIFY OP_CHECKSIG","hex":"76a9144517b65ac830ada301eefdc69ee8e77e7dc5c7a888ac","reqSigs":1,"type":"pubkeyhash"},"value":0.02187361,"valueZat":2187361},{"n":1,"scriptPubKey":{"addresses":["t1fBd4WQXeU79uCZFf1hA289y46etcnV4SE"],"asm":"OP_DUP OP_HASH160 e9c30259faac70f16ea4016c6890c02142e292fb OP_EQUALVERIFY OP_CHECKSIG","hex":"76a914e9c30259faac70f16ea4016c6890c02142e292fb88ac","reqSigs":1,"type":"pubkeyhash"},"value":0.0785195,"valueZat":7851950}],"vjoinsplit":[],"vShieldedOutput":0,"vShieldedSpend":0,"valueBalance":0,"value":0.10041761,"outputValue":0.10039311,"shieldedValue":0,"overwintered":false}]

To run: bundle exec ruby app/main.rb

ZCash transaction fields:
 * hash: "8c014827d672b0ec553c1818025424ed735a07d04f5b4fa903f7ae792908b899"
 * mainChain: false
 * fee: 0.0000245
 * type: "valueTransfer"
 * shielded: false
 * index: -1
 * blockHash: ""
 * blockHeight: -1
 * version: 4
 * lockTime: 0
 * timestamp: 1606235732
 * time: 1606235732
 * vin: ARRAY of hashes
 * vout: ARRAY of hashes
 * vjoinsplit: ARRAY of ???
 * vShieldedOutput: 0
 * vShieldedSpend: 0
 * valueBalance: 0
 * value: 0.10715223
 * outputValue: 0.10712773
 * shieldedValue: 0
 * overwintered: false

