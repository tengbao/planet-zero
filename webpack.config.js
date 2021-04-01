const path = require('path')
const webpack = require('webpack')
const JavaScriptObfuscator = require('webpack-obfuscator')

module.exports = {
  entry: {
    'game.min': './game.coffee'
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, '.')
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [ 'coffee-loader' ]
      },
    ],
  },
  plugins: [
    // new JavaScriptObfuscator({
    //   include: /\.min\.js$/,
    //   rotateUnicodeArray: true
    // }),
    new webpack.optimize.UglifyJsPlugin({
      include: /\.min\.js$/,
      minimize: true
    }),
    new webpack.optimize.ModuleConcatenationPlugin(),
  ]
}